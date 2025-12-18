# frozen_string_literal: true

# UI rendering methods

module Sergeant
  module Rendering
    def draw_screen
      clear

      max_y = lines - 1
      max_x = cols

      setpos(0, 0)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌─ Sergeant - 'Leave it to the Sarge!' ".ljust(max_x, '─'))
      end

      setpos(1, 0)
      branch = get_git_branch

      # Build status info
      status_parts = []
      status_parts << "Marked: #{@marked_items.length}" unless @marked_items.empty?
      unless @copied_items.empty?
        mode_text = @cut_mode ? 'Cut' : 'Copied'
        status_parts << "#{mode_text}: #{@copied_items.length}"
      end
      status_text = status_parts.empty? ? '' : " | #{status_parts.join(' | ')}"

      if branch
        branch_text = " [#{branch}]"
        path_max_length = max_x - 4 - branch_text.length - status_text.length
        path_display = @current_dir.length > path_max_length ? "...#{@current_dir[(-path_max_length + 3)..]}" : @current_dir

        attron(color_pair(5)) do
          addstr("│ #{path_display}")
        end
        attron(color_pair(6) | Curses::A_BOLD) do
          addstr(branch_text)
        end
        unless status_text.empty?
          attron(color_pair(1) | Curses::A_BOLD) do
            addstr(status_text)
          end
        end
        remaining = max_x - 2 - path_display.length - branch_text.length - status_text.length
      else
        path_max_length = max_x - 4 - status_text.length
        path_display = @current_dir.length > path_max_length ? "...#{@current_dir[(-path_max_length + 3)..]}" : @current_dir

        attron(color_pair(5)) do
          addstr("│ #{path_display}")
        end
        unless status_text.empty?
          attron(color_pair(1) | Curses::A_BOLD) do
            addstr(status_text)
          end
        end
        remaining = max_x - 2 - path_display.length - status_text.length
      end
      addstr(''.ljust(remaining)) if remaining.positive?

      setpos(2, 0)
      attron(color_pair(4)) do
        addstr('├'.ljust(max_x, '─'))
      end

      # Check if we need two lines for footer (narrow terminal)
      footer_lines = needs_two_line_footer?(max_x) ? 2 : 1

      setpos(max_y, 0)
      draw_footer(max_x, max_y)

      visible_lines = max_y - 3 - footer_lines

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
        elsif item[:type] == :directory
          attron(color_pair(1)) do
            draw_item(item, max_x, false)
          end
        else
          attron(color_pair(2) | Curses::A_DIM) do
            draw_item(item, max_x, false)
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
          addstr('█')
        end
      end

      refresh
    end

    def draw_item(item, max_x, is_selected)
      icon = item[:type] == :directory ? '📁 ' : '📄 '

      # Check if item is marked
      is_marked = @marked_items.include?(item[:path])
      mark_indicator = is_marked ? '✓ ' : '  '

      prefix = is_selected ? '▶ ' : '  '

      size_str = format_size(item[:size])
      date_str = format_date(item[:mtime])

      if @show_ownership && item[:owner] && item[:perms]
        perms_str = item[:perms]
        owner_str = item[:owner].ljust(16)
        metadata_space = perms_str.length + owner_str.length + size_str.length + date_str.length + 8
      else
        perms_str = ''
        owner_str = ''
        metadata_space = size_str.length + date_str.length + 4
      end

      available = max_x - prefix.length - mark_indicator.length - icon.length - metadata_space - 1

      name = if item[:name].length > available
               "#{item[:name][0...(available - 3)]}..."
             else
               item[:name].ljust(available)
             end

      display = if @show_ownership && item[:owner] && item[:perms]
                  "#{prefix}#{mark_indicator}#{icon}#{name}  #{perms_str}  #{owner_str}  #{size_str}  #{date_str}".ljust(max_x)
                else
                  "#{prefix}#{mark_indicator}#{icon}#{name}  #{size_str}  #{date_str}".ljust(max_x)
                end

      addstr(display)
    end

    def needs_two_line_footer?(max_x)
      # Check if terminal is narrow enough to need two-line footer
      short_help = 'jk:Move  ⏎:Open  h:Back  Spc:Mark  c:Copy  x:Cut  p:Paste  d:Del  m:Help  q:Quit'
      help_line1 = 'jk:Move  ⏎:Open  h:Back  Spc:Mark  c:Copy  x:Cut'

      max_x < short_help.length + 3 && max_x >= help_line1.length + 3
    end

    def draw_footer(max_x, max_y)
      # Define help text variations based on terminal width
      full_help = '↑↓/jk:Move  Enter:Open  ←h:Back  Space:Mark  c:Copy  x:Cut  p:Paste  d:Del  m:Help  q:Quit'
      medium_help = '↑↓/jk:Move  ⏎:Open  ←h:Back  Space:Mark  c:Copy  x:Cut  p:Paste  d:Del  m:Help  q:Quit'
      compact_help = '↑↓/jk:Move  ⏎:Open  ←:Back  Spc:Mark  c:Copy  x:Cut  p:Paste  d:Del  m:Help  q:Quit'
      short_help = 'jk:Move  ⏎:Open  h:Back  Spc:Mark  c:Copy  x:Cut  p:Paste  d:Del  m:Help  q:Quit'

      # Two-line help for very narrow terminals
      help_line1 = 'jk:Move  ⏎:Open  h:Back  Spc:Mark  c:Copy  x:Cut'
      help_line2 = 'p:Paste  d:Del  r:Rename  m:Help  q:Quit'

      help_text_length = full_help.length + 3 # +3 for "└─ " prefix

      if max_x >= help_text_length
        # Wide terminal: use full help text
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr("└─ #{full_help}".ljust(max_x, ' '))
        end
      elsif max_x >= medium_help.length + 3
        # Medium terminal: use medium help text
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr("└─ #{medium_help}".ljust(max_x, ' '))
        end
      elsif max_x >= compact_help.length + 3
        # Compact terminal: use compact help text
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr("└─ #{compact_help}".ljust(max_x, ' '))
        end
      elsif max_x >= short_help.length + 3
        # Short terminal: use short help text
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr("└─ #{short_help}".ljust(max_x, ' '))
        end
      elsif max_x >= help_line1.length + 3
        # Very narrow terminal: split into two lines
        setpos(max_y - 1, 0)
        attron(color_pair(4)) do
          addstr("├─ #{help_line1}".ljust(max_x, ' '))
        end
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr("└─ #{help_line2}".ljust(max_x, ' '))
        end
      else
        # Extremely narrow: just show minimal help
        setpos(max_y, 0)
        attron(color_pair(4)) do
          addstr('└─ m:Help  q:Quit'.ljust(max_x, ' '))
        end
      end
    end
  end
end
