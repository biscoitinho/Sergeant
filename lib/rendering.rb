# UI rendering methods

module Sergeant
  module Rendering
    def draw_screen
      clear

      max_y = lines - 1
      max_x = cols

      setpos(0, 0)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌─ Sergeant Navigator ".ljust(max_x, '─'))
      end

      setpos(1, 0)
      branch = get_git_branch
      
      if branch
        branch_text = " [#{branch}]"
        path_max_length = max_x - 4 - branch_text.length
        path_display = @current_dir.length > path_max_length ? "...#{@current_dir[-path_max_length+3..-1]}" : @current_dir
        
        attron(color_pair(5)) do
          addstr("│ #{path_display}")
        end
        attron(color_pair(6) | Curses::A_BOLD) do
          addstr(branch_text)
        end
        addstr("".ljust(max_x - 2 - path_display.length - branch_text.length))
      else
        attron(color_pair(5)) do
          path_display = @current_dir.length > max_x - 4 ? "...#{@current_dir[-max_x+7..-1]}" : @current_dir
          addstr("│ #{path_display}".ljust(max_x))
        end
      end

      setpos(2, 0)
      attron(color_pair(4)) do
        addstr("├".ljust(max_x, '─'))
      end

      setpos(max_y, 0)
      attron(color_pair(4)) do
        help = "↑↓/jk:Move  Enter/→l:Open  ←h:Back  /:Search  b:Bookmark  o:Owner  q/ESC:Select"
        addstr("└─ #{help}".ljust(max_x, ' '))
      end

      visible_lines = max_y - 4

      if @selected_index < @scroll_offset
        @scroll_offset = @selected_index
      elsif @selected_index >= @scroll_offset + visible_lines
        @scroll_offset = @selected_index - visible_lines + 1
      end

      visible_items = @items[@scroll_offset, visible_lines] || []
      visible_items.each_with_index do |item, idx|
        line_num = idx + 3
        actual_index = @scroll_offset + idx

        setpos(line_num, 0)

        is_selected = actual_index == @selected_index

        if is_selected
          attron(color_pair(3) | Curses::A_BOLD) do
            draw_item(item, max_x, true)
          end
        else
          if item[:type] == :directory
            attron(color_pair(1)) do
              draw_item(item, max_x, false)
            end
          else
            attron(color_pair(2) | Curses::A_DIM) do
              draw_item(item, max_x, false)
            end
          end
        end
      end

      if @items.length > visible_lines
        total = @items.length
        visible = visible_lines
        scroll_pos = (@scroll_offset.to_f / (total - visible)) * (visible - 1)
        scroll_pos = scroll_pos.round.clamp(0, visible - 1)

        setpos(3 + scroll_pos, max_x - 1)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("█")
        end
      end

      refresh
    end

    def draw_item(item, max_x, is_selected)
      icon = item[:type] == :directory ? "📁 " : "📄 "
      prefix = is_selected ? "▶ " : "  "

      size_str = format_size(item[:size])
      date_str = format_date(item[:mtime])
      
      if @show_ownership && item[:owner] && item[:perms]
        perms_str = item[:perms]
        owner_str = item[:owner].ljust(16)
        metadata_space = perms_str.length + owner_str.length + size_str.length + date_str.length + 8
      else
        perms_str = ""
        owner_str = ""
        metadata_space = size_str.length + date_str.length + 4
      end
      
      available = max_x - prefix.length - icon.length - metadata_space - 1
      
      name = if item[:name].length > available
        "#{item[:name][0...available-3]}..."
      else
        item[:name].ljust(available)
      end

      if @show_ownership && item[:owner] && item[:perms]
        display = "#{prefix}#{icon}#{name}  #{perms_str}  #{owner_str}  #{size_str}  #{date_str}".ljust(max_x)
      else
        display = "#{prefix}#{icon}#{name}  #{size_str}  #{date_str}".ljust(max_x)
      end
      
      addstr(display)
    end
  end
end

