# frozen_string_literal: true

# Help modal

module Sergeant
  module Modals
    module Help
      def show_help_modal
        max_y = lines
        max_x = cols

        modal_height = 24
        modal_width = 70
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        (modal_y..(modal_y + modal_height)).each do |y|
          setpos(y, modal_x)
          attron(color_pair(3)) do
            addstr(' ' * modal_width)
          end
        end

        setpos(modal_y, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
        end

        setpos(modal_y + 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end
        attron(color_pair(5) | Curses::A_BOLD) do
          addstr(' Key Mappings '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        help_lines = [
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
          '',
          'Other:',
          '  v                 - Preview file (markdown with glow, code with vim)',
          '  o                 - Toggle ownership display',
          '  b                 - Go to bookmark',
          '  /                 - Search files (with fzf if available)',
          '  q / ESC           - Quit and cd to current directory'
        ]

        help_lines.each_with_index do |line, idx|
          setpos(modal_y + 3 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          if line.start_with?('Navigation:', 'File Operations:', 'Other:')
            attron(color_pair(1) | Curses::A_BOLD) do
              addstr(line.ljust(modal_width - 4))
            end
          else
            addstr(line.ljust(modal_width - 4))
          end
          attron(color_pair(4)) do
            addstr(' │')
          end
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh
        getch
      end
    end
  end
end
