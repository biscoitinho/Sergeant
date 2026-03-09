# frozen_string_literal: true

# Simple dialog modals (error, info, confirmation)

module Sergeant
  module Modals
    module Dialogs
      def show_error_modal(message)
        max_y = lines
        max_x = cols

        modal_height = 7
        modal_width = [message.length + 10, 50].max
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
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr(' Error '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr(message.center(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr('│')
        end
        attron(color_pair(4) | Curses::A_DIM) do
          addstr(' Press any key to continue '.center(modal_width - 2))
        end
        attron(color_pair(4)) do
          addstr('│')
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh
        getch
      end

      def show_info_modal(message)
        max_y = lines
        max_x = cols

        modal_height = 7
        modal_width = [message.length + 10, 50].max
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
          addstr(' Info '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr(message.center(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr('│')
        end
        attron(color_pair(4) | Curses::A_DIM) do
          addstr(' Press any key to continue '.center(modal_width - 2))
        end
        attron(color_pair(4)) do
          addstr('│')
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh
        getch
      end

      def confirm_delete_modal(count)
        max_y = lines
        max_x = cols

        modal_height = 9
        modal_width = 60
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
          addstr(' Confirm Delete '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        msg1 = "Delete #{count} item(s) permanently?"
        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr(msg1.center(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        msg2 = 'This action cannot be undone!'
        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        attron(Curses::A_BOLD) do
          addstr(msg2.center(modal_width - 4))
        end
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
        end

        options = [
          'y - Yes, delete',
          'n - No, cancel'
        ]

        options.each_with_index do |opt, idx|
          setpos(modal_y + 6 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          addstr(opt.center(modal_width - 4))
          attron(color_pair(4)) do
            addstr(' │')
          end
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh

        loop do
          ch = getch
          case ch
          when 'y', 'Y'
            return true
          when 'n', 'N', 27 # ESC
            return false
          end
        end
      end

      def ask_conflict_resolution(filename)
        max_y = lines
        max_x = cols

        modal_height = 10
        modal_width = [filename.length + 30, 60].min
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
          addstr(' File Conflict '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        msg = 'File already exists:'
        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr(msg.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        attron(color_pair(1) | Curses::A_BOLD) do
          display_name = filename.length > modal_width - 6 ? "#{filename[0..(modal_width - 10)]}..." : filename
          addstr(display_name.ljust(modal_width - 4))
        end
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
        end

        options = [
          's - Skip',
          'o - Overwrite',
          'r - Rename'
        ]

        options.each_with_index do |opt, idx|
          setpos(modal_y + 6 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          addstr(opt.ljust(modal_width - 4))
          attron(color_pair(4)) do
            addstr(' │')
          end
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh

        loop do
          ch = getch
          case ch
          when 's', 'S'
            return :skip
          when 'o', 'O'
            return :overwrite
          when 'r', 'R'
            return :rename
          when 27 # ESC
            return :skip
          end
        end
      end

      def draw_progress_modal(title, total)
        max_y = lines
        max_x = cols

        modal_width = [60, max_x - 4].min
        modal_height = 7
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        @progress_modal = { y: modal_y, x: modal_x, width: modal_width, total: total }

        # Draw background
        (modal_y..(modal_y + modal_height)).each do |y|
          setpos(y, modal_x)
          attron(color_pair(3)) { addstr(' ' * modal_width) }
        end

        # Top border
        setpos(modal_y, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
        end

        # Title row
        setpos(modal_y + 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) { addstr('│') }
        attron(color_pair(5) | Curses::A_BOLD) { addstr(" #{title} ".center(modal_width - 2)) }
        attron(color_pair(4) | Curses::A_BOLD) { addstr('│') }

        # Separator
        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) { addstr("\u251C#{'─' * (modal_width - 2)}\u2524") }

        # Filename row (blank initially)
        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) { addstr('│ ') }
        addstr(' ' * (modal_width - 4))
        attron(color_pair(4)) { addstr(' │') }

        # Spacer row
        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) { addstr("\u2502#{' ' * (modal_width - 2)}\u2502") }

        # Progress bar row (blank initially)
        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) { addstr('│ ') }
        addstr(' ' * (modal_width - 4))
        attron(color_pair(4)) { addstr(' │') }

        # Bottom border
        setpos(modal_y + 6, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh
      end

      def update_progress_modal(current, total, filename)
        return unless @progress_modal

        modal_y  = @progress_modal[:y]
        modal_x  = @progress_modal[:x]
        modal_width = @progress_modal[:width]
        inner_width = modal_width - 4 # between '│ ' and ' │'

        # Update filename line
        setpos(modal_y + 3, modal_x + 2)
        display_name = filename.to_s
        display_name = "...#{display_name[-(inner_width - 3)..]}" if display_name.length > inner_width
        addstr(display_name.ljust(inner_width))

        # Build progress bar
        percent   = total > 0 ? (current.to_f / total * 100).round : 0
        count_str = "#{current}/#{total} (#{percent}%)"
        bar_outer = [inner_width - count_str.length - 1, 3].max # 1 space between bar and count
        bar_inner = bar_outer - 2 # subtract [ and ]
        filled    = total > 0 ? (current.to_f / total * bar_inner).round : 0
        empty     = bar_inner - filled

        bar = "[#{'█' * filled}#{'░' * empty}] #{count_str}"
        setpos(modal_y + 5, modal_x + 2)
        addstr(bar.ljust(inner_width))

        refresh
      end

      def show_error_with_retry(filepath, error_message)
        max_y = lines
        max_x = cols

        # Calculate modal dimensions based on message length
        message_lines = [
          "Error with:",
          filepath.length > 60 ? "...#{filepath[-60..]}" : filepath,
          "",
          error_message.length > 60 ? error_message[0...60] : error_message
        ]

        modal_height = 11
        modal_width = [70, max_x - 4].min
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        # Draw modal background
        (modal_y..(modal_y + modal_height)).each do |y|
          setpos(y, modal_x)
          attron(color_pair(3)) do
            addstr(' ' * modal_width)
          end
        end

        # Draw border and title
        setpos(modal_y, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
        end

        setpos(modal_y + 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr(' Error '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        # Draw message lines
        message_lines.each_with_index do |line, idx|
          setpos(modal_y + 3 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          addstr(line.ljust(modal_width - 4))
          attron(color_pair(4)) do
            addstr(' │')
          end
        end

        # Draw separator
        setpos(modal_y + 7, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        # Draw options
        setpos(modal_y + 8, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr('[S]kip  [R]etry  [A]bort'.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 9, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr('Choose action:'.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        # Draw bottom border
        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh

        # Handle input
        loop do
          ch = getch
          case ch
          when 's', 'S'
            return :skip
          when 'r', 'R'
            return :retry
          when 'a', 'A', 27  # A or ESC = abort
            return :abort
          end
        end
      end
    end
  end
end
