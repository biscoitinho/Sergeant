#!/usr/bin/env ruby
# Sergeant (sgt) - Interactive TUI directory navigator
# Navigate directories with arrow keys, press Enter to cd

require 'curses'
require 'pathname'

class Sergeant
  include Curses

  def initialize
    @current_dir = Dir.pwd
    @selected_index = 0
    @scroll_offset = 0
  end

  def run
    init_screen
    start_color
    curs_set(0)  # Hide cursor
    noecho
    stdscr.keypad(true)  # Enable arrow keys!

    # Define color pairs
    init_pair(1, COLOR_CYAN, COLOR_BLACK)    # Directories
    init_pair(2, COLOR_WHITE, COLOR_BLACK)   # Files (dimmed)
    init_pair(3, COLOR_BLACK, COLOR_CYAN)    # Selected item
    init_pair(4, COLOR_YELLOW, COLOR_BLACK)  # Header
    init_pair(5, COLOR_GREEN, COLOR_BLACK)   # Current path

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
        when 10, 13, Curses::Key::RIGHT, 'l'  # Enter or Right - navigate into directory
          item = @items[@selected_index]
          if item && item[:type] == :directory
            @current_dir = item[:path]
            @selected_index = 0
            @scroll_offset = 0
          end
        when 'q', 27  # q or ESC - select current directory and exit
          close_screen
          puts @current_dir
          exit 0
        when Curses::Key::LEFT, 'h'  # Left or h - go up one directory
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
    rescue => e
      close_screen
      puts "Error: #{e.message}"
      puts e.backtrace
      exit 1
    end
  end

  private

  def refresh_items
    entries = Dir.entries(@current_dir).reject { |e| e == '.' }

    @items = []

    # Add parent directory entry if not at root
    unless @current_dir == '/'
      @items << {
        name: '..',
        type: :directory,
        path: File.dirname(@current_dir)
      }
    end

    # Separate directories and files
    directories = []
    files = []

    entries.each do |entry|
      full_path = File.join(@current_dir, entry)
      begin
        if File.directory?(full_path)
          directories << {
            name: entry,
            type: :directory,
            path: File.absolute_path(full_path)
          }
        else
          files << {
            name: entry,
            type: :file,
            path: File.absolute_path(full_path)
          }
        end
      rescue Errno::EACCES, Errno::ENOENT
        # Skip files we can't access
      end
    end

    # Sort and combine: directories first, then files
    directories.sort_by! { |d| d[:name].downcase }
    files.sort_by! { |f| f[:name].downcase }

    @items += directories + files

    # Adjust selection if out of bounds
    @selected_index = [@selected_index, @items.length - 1].min
    @selected_index = 0 if @selected_index < 0
  end

  def draw_screen
    clear

    max_y = lines - 1
    max_x = cols

    # Draw header
    setpos(0, 0)
    attron(color_pair(4) | A_BOLD) do
      addstr("┌─ Sergeant Navigator ".ljust(max_x, '─'))
    end

    # Draw current path
    setpos(1, 0)
    attron(color_pair(5)) do
      path_display = @current_dir.length > max_x - 4 ? "...#{@current_dir[-max_x+7..-1]}" : @current_dir
      addstr("│ #{path_display}".ljust(max_x))
    end

    # Draw separator
    setpos(2, 0)
    attron(color_pair(4)) do
      addstr("├".ljust(max_x, '─'))
    end

    # Draw help line
    setpos(max_y, 0)
    attron(color_pair(4)) do
      help = "↑↓/jk:Move  Enter/→l:Open  ←h:Back  q/ESC:Select"
      addstr("└─ #{help}".ljust(max_x, ' '))
    end

    # Calculate visible area
    visible_lines = max_y - 4  # Subtract header, path, separator, and footer

    # Adjust scroll offset
    if @selected_index < @scroll_offset
      @scroll_offset = @selected_index
    elsif @selected_index >= @scroll_offset + visible_lines
      @scroll_offset = @selected_index - visible_lines + 1
    end

    # Draw items
    visible_items = @items[@scroll_offset, visible_lines] || []
    visible_items.each_with_index do |item, idx|
      line_num = idx + 3
      actual_index = @scroll_offset + idx

      setpos(line_num, 0)

      is_selected = actual_index == @selected_index

      if is_selected
        attron(color_pair(3) | A_BOLD) do
          draw_item(item, max_x, true)
        end
      else
        if item[:type] == :directory
          attron(color_pair(1)) do
            draw_item(item, max_x, false)
          end
        else
          attron(color_pair(2) | A_DIM) do
            draw_item(item, max_x, false)
          end
        end
      end
    end

    # Draw scrollbar indicator if needed
    if @items.length > visible_lines
      total = @items.length
      visible = visible_lines
      scroll_pos = (@scroll_offset.to_f / (total - visible)) * (visible - 1)
      scroll_pos = scroll_pos.round.clamp(0, visible - 1)

      setpos(3 + scroll_pos, max_x - 1)
      attron(color_pair(4) | A_BOLD) do
        addstr("█")
      end
    end

    refresh
  end

  def draw_item(item, max_x, is_selected)
    icon = item[:type] == :directory ? "📁 " : "📄 "
    prefix = is_selected ? "▶ " : "  "

    # Calculate available space
    available = max_x - prefix.length - icon.length - 1
    name = item[:name].length > available ? "#{item[:name][0...available-3]}..." : item[:name]

    display = "#{prefix}#{icon}#{name}".ljust(max_x)
    addstr(display)
  end

  def move_selection(delta)
    return if @items.empty?

    @selected_index = (@selected_index + delta).clamp(0, @items.length - 1)
  end
end

# Run the navigator
Sergeant.new.run

