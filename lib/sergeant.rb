# frozen_string_literal: true

# Sergeant (sgt) - Interactive TUI directory navigator
# Navigate directories with arrow keys, press Enter to cd

require 'curses'
require 'pathname'
require 'etc'
require 'fileutils'

require_relative 'sergeant/version'
require_relative 'sergeant/config'
require_relative 'sergeant/utils'
require_relative 'sergeant/modals'
require_relative 'sergeant/rendering'

# Main application class for Sergeant
class SergeantApp
  include Curses
  include Sergeant::Utils
  include Sergeant::Modals
  include Sergeant::Rendering

  def initialize(start_dir: nil, no_color: false, pwd_mode: false, restore_session: false)
    @current_dir = start_dir || Dir.pwd
    @selected_index = 0
    @scroll_offset = 0
    @show_ownership = false
    @last_show_ownership = false
    @no_color = no_color
    @pwd_mode = pwd_mode
    @config = Sergeant::Config.load_config
    @bookmarks = Sergeant::Config.load_bookmarks
    @marked_items = []
    @copied_items = []
    @cut_mode = false
    @last_refreshed_dir = nil
    @items = []
    @filter_text = ''
    @all_items = []

    # Stat caching for performance
    @stat_cache = {}
    @cache_ttl = 5  # seconds
    @max_cache_entries = 5000

    # Session persistence
    @session_file = File.expand_path('~/.sgt_session')
    if restore_session && File.exist?(@session_file)
      saved_dir = File.read(@session_file).strip
      @current_dir = saved_dir if File.directory?(saved_dir)
    end

    # Recent directories history
    @history_file = File.expand_path('~/.sgt_history')
    @directory_history = load_history
    @history_max_size = 50
  end

  def run
    init_screen

    # Only initialize colors if terminal supports them and not disabled
    if !@no_color && has_colors?
      start_color
      apply_color_theme
    end

    curs_set(0)
    noecho
    stdscr.keypad(true)

    begin
      loop do
        # Only refresh items when directory changes, not on every keystroke
        refresh_items_if_needed
        draw_screen

        key = getch
        case key
        when Curses::Key::UP, 'k'
          move_selection(-1)
        when Curses::Key::DOWN, 'j'
          move_selection(1)
        when 10, 13, Curses::Key::RIGHT, 'l'
          item = @items[@selected_index]
          if item && item[:type] == :directory
            @current_dir = item[:path]
            @selected_index = 0
            @scroll_offset = 0
          elsif item && item[:type] == :file
            preview_file
          end
        when 'b'
          goto_bookmark
        when 'o'
          @show_ownership = !@show_ownership
        when 'e'
          edit_file
        when 'v'
          preview_file
        when 32, ' '
          toggle_mark
        when 'c'
          copy_marked_items
        when 'x'
          cut_marked_items
        when 'd'
          delete_marked_items
        when 'r'
          rename_item
        when 'p'
          paste_items
        when 'u'
          unmark_all
        when 'm'
          show_help_modal
        when 'n'
          create_new_with_modal
        when ':'
          execute_terminal_command
        when '/'
          search_files
        when 'f'
          filter_current_view
        when 'H'
          show_history_modal
        when 'R'
          # Force refresh and clear cache
          @stat_cache.clear
          force_refresh
        when 'q', 27
          close_screen
          save_session  # Save current directory for --restore
          puts @current_dir
          exit 0
        when Curses::Key::LEFT, 'h'
          parent = File.dirname(@current_dir)
          if parent != @current_dir
            @current_dir = parent
            @selected_index = 0
            @scroll_offset = 0
          end
        end
      end
    rescue Interrupt
      close_screen
      save_session
      exit 0
    rescue StandardError => e
      close_screen
      puts "Error: #{e.message}"
      puts e.backtrace
      exit 1
    end
  end

  private

  def apply_color_theme
    init_pair(1, Sergeant::Config.get_color(@config['directories']), Curses::COLOR_BLACK)
    init_pair(2, Sergeant::Config.get_color(@config['files']), Curses::COLOR_BLACK)
    init_pair(3, Sergeant::Config.get_color(@config['selected_fg']),
              Sergeant::Config.get_color(@config['selected_bg']))
    init_pair(4, Sergeant::Config.get_color(@config['header']), Curses::COLOR_BLACK)
    init_pair(5, Sergeant::Config.get_color(@config['path']), Curses::COLOR_BLACK)
    init_pair(6, Sergeant::Config.get_color(@config['git_branch']), Curses::COLOR_BLACK)
  end

  def search_files
    close_screen

    if fzf_available?
      fzf_cmd = 'fzf --height=40% --reverse --prompt="Search: " ' \
                '--preview="ls -lah {}" --preview-window=right:50%'
      selected = `find "#{@current_dir}" -type f -o -type d 2>/dev/null | #{fzf_cmd}`.strip
    else
      puts 'fzf not found - using fallback search'
      print 'Search (regex): '
      query = gets.chomp

      if query.empty?
        selected = nil
      else
        results = `find "#{@current_dir}" 2>/dev/null | grep -i "#{query}"`.split("\n")

        if results.empty?
          puts 'No results found. Press Enter to continue...'
          gets
          selected = nil
        elsif results.length == 1
          selected = results.first
        else
          puts "\nResults:"
          results.first(20).each_with_index do |result, idx|
            puts "#{idx + 1}. #{result}"
          end
          puts '...' if results.length > 20
          print "\nSelect number (or Enter to cancel): "
          choice = gets.chomp
          selected = choice.empty? ? nil : results[choice.to_i - 1]
        end
      end
    end

    init_screen
    if has_colors?
      start_color
      apply_color_theme
    end
    curs_set(0)
    noecho
    stdscr.keypad(true)

    return unless selected && !selected.empty?

    @current_dir = if File.directory?(selected)
                     selected
                   else
                     File.dirname(selected)
                   end
    @selected_index = 0
    @scroll_offset = 0
  end

  # Stat caching for performance
  def cached_stat(path)
    now = Time.now

    # Check if we have a cached stat for this path
    if @stat_cache[path]
      cached_entry = @stat_cache[path]
      age = now - cached_entry[:time]

      # If cache is still fresh (less than TTL), return it
      return cached_entry[:stat] if age < @cache_ttl
    end

    # Cache miss or expired - fetch fresh stat
    stat = File.stat(path)

    # Store in cache with timestamp
    @stat_cache[path] = {
      stat: stat,
      time: now
    }

    # Cleanup cache if it's too large
    cleanup_cache if @stat_cache.size > @max_cache_entries

    stat
  rescue Errno::ENOENT, Errno::EACCES
    # File was deleted or no permission - remove from cache
    @stat_cache.delete(path)
    nil
  end

  def clear_cache_for_directory(dir)
    # Remove all cached stats for files in this directory
    @stat_cache.delete_if { |path, _| path.start_with?(dir) }
  end

  def cleanup_cache
    now = Time.now

    # Remove entries older than TTL
    @stat_cache.delete_if do |_, entry|
      (now - entry[:time]) > @cache_ttl
    end

    # If still too large, remove oldest entries
    if @stat_cache.size > @max_cache_entries
      sorted = @stat_cache.sort_by { |_, entry| entry[:time] }
      to_remove = @stat_cache.size - @max_cache_entries
      sorted.first(to_remove).each do |path, _|
        @stat_cache.delete(path)
      end
    end
  end

  # Session persistence
  def save_session
    File.write(@session_file, @current_dir)
  rescue StandardError
    # Silently ignore session save errors
  end

  # Directory history
  def load_history
    return [] unless File.exist?(@history_file)

    File.readlines(@history_file).map(&:strip).reject(&:empty?)
  rescue StandardError
    []
  end

  def save_history
    File.write(@history_file, @directory_history.join("\n"))
  rescue StandardError
    # Silently ignore history save errors
  end

  def add_to_history(dir)
    # Don't add duplicates or current dir if it's already at the top
    return if @directory_history.first == dir

    # Remove dir if it exists elsewhere in history
    @directory_history.delete(dir)

    # Add to front
    @directory_history.unshift(dir)

    # Trim to max size
    @directory_history = @directory_history.first(@history_max_size)

    save_history
  end

  def refresh_items_if_needed
    # Only refresh if directory has changed, or if showing ownership toggle changed
    # This prevents expensive file system operations on every keystroke
    if @current_dir != @last_refreshed_dir || @show_ownership != @last_show_ownership
      refresh_items
      @last_refreshed_dir = @current_dir
      @last_show_ownership = @show_ownership

      # Add to history when directory changes
      add_to_history(@current_dir) if @current_dir != @last_refreshed_dir
    end
  end

  def force_refresh
    # Force a refresh even if directory hasn't changed (e.g., after file operations)
    @last_refreshed_dir = nil

    # Also clear cache for current directory
    clear_cache_for_directory(@current_dir)
  end

  def refresh_items
    entries = Dir.entries(@current_dir).reject { |e| e == '.' || e == '..' }
    @items = []

    unless @current_dir == '/'
      @items << {
        name: '..',
        type: :directory,
        path: File.dirname(@current_dir),
        size: nil,
        mtime: nil,
        owner: nil,
        perms: nil
      }
    end

    directories = []
    files = []

    entries.each do |entry|
      full_path = File.join(@current_dir, entry)
      begin
        stat = cached_stat(full_path)  # Use cached stat for performance
        next unless stat  # Skip if file was deleted or no permission

        is_dir = stat.directory?  # Use stat instead of File.directory? (saves syscall)
        owner_info = @show_ownership ? get_owner_info(stat) : nil  # Only fetch if needed
        perms = @show_ownership ? format_permissions(stat.mode, is_dir) : nil

        if is_dir
          directories << {
            name: entry,
            type: :directory,
            path: File.absolute_path(full_path),
            size: stat.size,
            mtime: stat.mtime,
            owner: owner_info,
            perms: perms
          }
        else
          files << {
            name: entry,
            type: :file,
            path: File.absolute_path(full_path),
            size: stat.size,
            mtime: stat.mtime,
            owner: owner_info,
            perms: perms
          }
        end
      rescue Errno::EACCES, Errno::ENOENT
      end
    end

    directories.sort_by! { |d| d[:name].downcase }
    files.sort_by! { |f| f[:name].downcase }

    @items += directories + files
    @all_items = @items.dup  # Store all items for filtering

    # Apply filter if active
    apply_filter if @filter_text && !@filter_text.empty?

    @selected_index = [@selected_index, @items.length - 1].min
    @selected_index = 0 if @selected_index.negative?
  end

  def apply_filter
    return if @filter_text.empty?

    # Filter items by name (case-insensitive), keep '..' entry
    @items = @all_items.select do |item|
      item[:name] == '..' || item[:name].downcase.include?(@filter_text.downcase)
    end
  end

  def move_selection(delta)
    return if @items.empty?

    @selected_index = (@selected_index + delta).clamp(0, @items.length - 1)

    # Flush input buffer to prevent lag on Windows when holding arrow keys
    # This clears any queued key-repeat events that accumulated during processing
    Curses.flushinp
  end

  def toggle_mark
    item = @items[@selected_index]
    return unless item && item[:name] != '..'

    path = item[:path]
    if @marked_items.include?(path)
      @marked_items.delete(path)
    else
      @marked_items << path
    end
  end

  def copy_marked_items
    return if @marked_items.empty?

    @copied_items = @marked_items.dup
    @cut_mode = false
    show_info_modal("#{@copied_items.length} item(s) copied")
  end

  def cut_marked_items
    return if @marked_items.empty?

    @copied_items = @marked_items.dup
    @cut_mode = true
    show_info_modal("#{@copied_items.length} item(s) cut")
  end

  def unmark_all
    @marked_items.clear
  end

  def delete_marked_items
    return if @marked_items.empty?

    return unless confirm_delete_modal(@marked_items.length)

    delete_with_modal
  end

  def rename_item
    item = @items[@selected_index]
    return unless item && item[:name] != '..'

    rename_with_modal(item)
  end

  def paste_items
    return if @copied_items.empty?

    paste_with_modal
  end
end
