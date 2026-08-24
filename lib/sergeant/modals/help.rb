# frozen_string_literal: true

# Help modal

module Sergeant
  module Modals
    module Help
      HELP_LINES = [
        'Navigation:',
        '  ↑/k               - Move up',
        '  ↓/j               - Move down',
        '  Enter / →/l       - Open directory or preview file',
        '  ←/h               - Go back to parent directory',
        '',
        'File Operations:',
        '  Space             - Mark/unmark item',
        '  c                 - Copy marked items',
        '  x                 - Cut marked items',
        '  p                 - Paste copied/cut items',
        '  d                 - Delete marked items',
        '  r                 - Rename current item',
        '  u                 - Unmark all items',
        '  n                 - Create new file or directory',
        '',
        'View & Search:',
        '  e                 - Edit file ($EDITOR, nano, nvim, vim)',
        '  f                 - Filter current directory view',
        '  /                 - Search files (with fzf if available)',
        '',
        'Other:',
        '  :                 - Execute terminal command',
        '  o                 - Toggle ownership display',
        '  P                 - Toggle side preview panel',
        '  [ / ]             - Shrink/grow side preview panel',
        '  b                 - Go to bookmark',
        '  H                 - Show recent directories history',
        '  R                 - Force refresh and clear cache',
        '  q / ESC           - Quit and cd to current directory'
      ].freeze

      HELP_SECTION_HEADERS = ['Navigation:', 'File Operations:', 'View & Search:', 'Other:'].freeze

      def show_help_modal
        max_y = lines
        max_x = cols

        modal_height = [HELP_LINES.length + 4, max_y - 4].min
        modal_width = [70, max_x - 4].min
        geometry = {
          y: (max_y - modal_height) / 2,
          x: (max_x - modal_width) / 2,
          width: modal_width,
          height: modal_height
        }
        visible_rows = modal_height - 4
        max_scroll = [HELP_LINES.length - visible_rows, 0].max
        scroll_offset = 0

        loop do
          draw_help_frame(geometry)
          draw_help_lines(geometry, visible_rows, scroll_offset)
          draw_help_scrollbar(geometry, visible_rows, scroll_offset, max_scroll)

          refresh

          case getch
          when Curses::Key::DOWN, 'j'
            scroll_offset = [scroll_offset + 1, max_scroll].min
          when Curses::Key::UP, 'k'
            scroll_offset = [scroll_offset - 1, 0].max
          else
            break
          end
        end
      end

      def draw_help_frame(geometry)
        y = geometry[:y]
        x = geometry[:x]
        width = geometry[:width]
        height = geometry[:height]

        (y..(y + height)).each do |row|
          setpos(row, x)
          attron(color_pair(3)) { addstr(' ' * width) }
        end

        setpos(y, x)
        attron(color_pair(4) | Curses::A_BOLD) { addstr("┌#{'─' * (width - 2)}┐") }

        setpos(y + 1, x)
        attron(color_pair(4) | Curses::A_BOLD) { addstr('│') }
        attron(color_pair(5) | Curses::A_BOLD) { addstr(' Key Mappings '.center(width - 2)) }
        attron(color_pair(4) | Curses::A_BOLD) { addstr('│') }

        setpos(y + 2, x)
        attron(color_pair(4)) { addstr("├#{'─' * (width - 2)}┤") }

        setpos(y + height - 1, x)
        attron(color_pair(4) | Curses::A_BOLD) { addstr("└#{'─' * (width - 2)}┘") }
      end

      def draw_help_lines(geometry, visible_rows, scroll_offset)
        visible_rows.times do |row|
          line = HELP_LINES[scroll_offset + row]

          setpos(geometry[:y] + 3 + row, geometry[:x])
          attron(color_pair(4)) { addstr('│ ') }
          draw_help_line_text(line, geometry[:width])
          attron(color_pair(4)) { addstr(' │') }
        end
      end

      def draw_help_line_text(line, width)
        unless line
          addstr(''.ljust(width - 4))
          return
        end

        display_line = if line.length > width - 4
                         "#{line[0...(width - 7)]}..."
                       else
                         line.ljust(width - 4)
                       end

        if HELP_SECTION_HEADERS.include?(line)
          attron(color_pair(1) | Curses::A_BOLD) { addstr(display_line) }
        else
          addstr(display_line)
        end
      end

      def draw_help_scrollbar(geometry, visible_rows, scroll_offset, max_scroll)
        return unless max_scroll.positive?

        scroll_pos = ((scroll_offset.to_f / max_scroll) * (visible_rows - 1)).round.clamp(0, visible_rows - 1)

        setpos(geometry[:y] + 3 + scroll_pos, geometry[:x] + geometry[:width] - 2)
        attron(color_pair(4) | Curses::A_BOLD) { addstr('█') }
      end
    end
  end
end
