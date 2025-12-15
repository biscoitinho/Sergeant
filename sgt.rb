#!/usr/bin/env ruby
# frozen_string_literal: true

# Sergeant (sgt) - Interactive TUI directory navigator
# Navigate directories with arrow keys, press Enter to cd

require 'curses'
require 'pathname'
require 'etc'
require_relative 'lib/config'
require_relative 'lib/utils'
require_relative 'lib/modals'
require_relative 'lib/rendering'

class SergeantApp
  include Curses
  include Sergeant::Utils
  include Sergeant::Modals
  include Sergeant::Rendering

  def initialize
    @current_dir = Dir.pwd
    @selected_index = 0
    @scroll_offset = 0
    @show_ownership = false
    @config = Sergeant::Config.load_config
    @bookmarks = Sergeant::Config.load_bookmarks
    @marked_items = []
    @copied_items = []
    @cut_mode = false
  end

  def run
    init_screen
    start_color
    curs_set(0)
    noecho
    stdscr.keypad(true)

    apply_color_theme

    begin
      loop do
        refresh_items
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
        when '/'
          search_files
        when 'q', 27
          close_screen
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
    start_color
    curs_set(0)
    noecho
    stdscr.keypad(true)
    apply_color_theme

    return unless selected && !selected.empty?

    @current_dir = if File.directory?(selected)
                     selected
                   else
                     File.dirname(selected)
                   end
    @selected_index = 0
    @scroll_offset = 0
  end

  def refresh_items
    entries = Dir.entries(@current_dir).reject { |e| e == '.' }

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
        stat = File.stat(full_path)
        owner_info = get_owner_info(stat)
        is_dir = File.directory?(full_path)
        perms = format_permissions(stat.mode, is_dir)

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

    @selected_index = [@selected_index, @items.length - 1].min
    @selected_index = 0 if @selected_index.negative?
  end

  def move_selection(delta)
    return if @items.empty?

    @selected_index = (@selected_index + delta).clamp(0, @items.length - 1)
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

# Run the navigator
SergeantApp.new.run
