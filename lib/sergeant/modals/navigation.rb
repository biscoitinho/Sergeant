# frozen_string_literal: true

# Navigation and bookmark modals

module Sergeant
  module Modals
    module Navigation
      def goto_bookmark
        return if @bookmarks.empty? && show_no_bookmarks_modal

        max_y = lines
        max_x = cols

        modal_height = [@bookmarks.length + 8, max_y - 4].min
        modal_width = [60, max_x - 4].min
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
          title = ' Bookmarks '.center(modal_width - 2)
          addstr(title)
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        visible_bookmarks = @bookmarks.to_a.first(modal_height - 7)
        visible_bookmarks.each_with_index do |(name, path), idx|
          setpos(modal_y + 3 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│')
          end

          attron(color_pair(1) | Curses::A_BOLD) do
            addstr(" #{name}".ljust(20))
          end

          path_space = modal_width - 23
          display_path = path.length > path_space ? "...#{path[-(path_space - 3)..]}" : path
          addstr(display_path.ljust(path_space - 1))

          attron(color_pair(4)) do
            addstr('│')
          end
        end

        (visible_bookmarks.length...(modal_height - 7)).each do |idx|
          setpos(modal_y + 3 + idx, modal_x)
          attron(color_pair(4)) do
            addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
          end
        end

        input_line = modal_y + modal_height - 4
        setpos(input_line, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        setpos(input_line + 1, modal_x)
        attron(color_pair(4)) do
          addstr('│')
        end
        prompt = ' Enter bookmark name: '
        attron(color_pair(5)) do
          addstr(prompt)
        end
        addstr(' ' * (modal_width - 2 - prompt.length))
        attron(color_pair(4)) do
          addstr('│')
        end

        setpos(input_line + 2, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end

        curs_set(1)
        echo
        setpos(input_line + 2, modal_x + 2)

        input_width = modal_width - 5
        bookmark_name = ''

        loop do
          ch = getch

          case ch
          when 10, 13
            break
          when 27
            bookmark_name = ''
            break
          when 127, Curses::Key::BACKSPACE
            if bookmark_name.length.positive?
              bookmark_name = bookmark_name[0...-1]
              setpos(input_line + 2, modal_x + 2)
              addstr(bookmark_name.ljust(input_width))
              setpos(input_line + 2, modal_x + 2 + bookmark_name.length)
            end
          else
            if ch.is_a?(String) && bookmark_name.length < input_width
              bookmark_name += ch
              setpos(input_line + 2, modal_x + 2)
              addstr(bookmark_name.ljust(input_width))
            end
          end

          refresh
        end

        noecho
        curs_set(0)

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        refresh

        bookmark_name = bookmark_name.strip

        return if bookmark_name.empty?

        if @bookmarks.key?(bookmark_name)
          target_path = @bookmarks[bookmark_name]
          if Dir.exist?(target_path)
            @current_dir = target_path
            @selected_index = 0
            @scroll_offset = 0
          else
            show_error_modal("Bookmark path doesn't exist")
          end
        else
          show_error_modal("Bookmark '#{bookmark_name}' not found")
        end
      end

      def show_no_bookmarks_modal
        max_y = lines
        max_x = cols

        modal_height = 10
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
          addstr(' No Bookmarks Defined '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        messages = [
          'Add bookmarks to ~/.sgtrc:',
          '',
          '[bookmarks]',
          'home=/home/user',
          'projects=~/projects'
        ]

        messages.each_with_index do |msg, idx|
          setpos(modal_y + 3 + idx, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          if idx > 1
            attron(color_pair(1)) do
              addstr(msg.ljust(modal_width - 4))
            end
          else
            addstr(msg.ljust(modal_width - 4))
          end
          attron(color_pair(4)) do
            addstr(' │')
          end
        end

        setpos(modal_y + 9, modal_x)
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
        true
      end

      def filter_current_view
        max_y = lines
        max_x = cols

        modal_height = 8
        modal_width = [70, max_x - 4].min
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        # Draw modal
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
          addstr(' Filter Current View '.center(modal_width - 2))
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
        addstr('Enter text to filter files/folders (ESC to clear):'.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        prompt = 'Filter: '
        attron(color_pair(5)) do
          addstr(prompt)
        end
        addstr(' ' * (modal_width - 4 - prompt.length))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 6, modal_x)
        attron(color_pair(4)) do
          addstr('│')
        end
        attron(color_pair(4) | Curses::A_DIM) do
          count = @all_items.length - (@all_items.any? { |i| i[:name] == '..' } ? 1 : 0)
          addstr(" #{count} items in current directory ".center(modal_width - 2))
        end
        attron(color_pair(4)) do
          addstr('│')
        end

        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        # Input handling
        curs_set(1)
        echo
        input_width = modal_width - 6 - prompt.length
        filter_input = @filter_text.dup

        setpos(modal_y + 4, modal_x + 2 + prompt.length)
        addstr(filter_input.ljust(input_width))
        setpos(modal_y + 4, modal_x + 2 + prompt.length + filter_input.length)

        loop do
          refresh
          ch = getch

          case ch
          when 10, 13  # Enter
            break
          when 27  # ESC - clear filter
            filter_input = ''
            break
          when 127, Curses::Key::BACKSPACE
            if filter_input.length.positive?
              filter_input = filter_input[0...-1]
              setpos(modal_y + 4, modal_x + 2 + prompt.length)
              addstr(filter_input.ljust(input_width))
              setpos(modal_y + 4, modal_x + 2 + prompt.length + filter_input.length)
            end
          else
            if ch.is_a?(String) && filter_input.length < input_width
              filter_input += ch
              setpos(modal_y + 4, modal_x + 2 + prompt.length)
              addstr(filter_input.ljust(input_width))
              setpos(modal_y + 4, modal_x + 2 + prompt.length + filter_input.length)
            end
          end
        end

        noecho
        curs_set(0)

        # Apply filter
        @filter_text = filter_input.strip
        @selected_index = 0
        @scroll_offset = 0
        force_refresh  # Force refresh to apply filter
      end

      def show_history_modal
        return if @directory_history.empty? && show_no_history_modal

        max_y = lines
        max_x = cols

        modal_height = [@directory_history.length + 8, max_y - 4].min
        modal_width = [70, max_x - 4].min
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        selected = 0
        scroll_offset = 0

        loop do
          # Draw modal background
          (modal_y..(modal_y + modal_height)).each do |y|
            setpos(y, modal_x)
            attron(color_pair(3)) do
              addstr(' ' * modal_width)
            end
          end

          # Draw border
          setpos(modal_y, modal_x)
          attron(color_pair(4) | Curses::A_BOLD) do
            addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
          end

          setpos(modal_y + 1, modal_x)
          attron(color_pair(4) | Curses::A_BOLD) do
            addstr('│')
          end
          attron(color_pair(5) | Curses::A_BOLD) do
            title = ' Recent Directories '.center(modal_width - 2)
            addstr(title)
          end
          attron(color_pair(4) | Curses::A_BOLD) do
            addstr('│')
          end

          setpos(modal_y + 2, modal_x)
          attron(color_pair(4)) do
            addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
          end

          # Draw history entries
          visible_height = modal_height - 7
          visible_history = @directory_history[scroll_offset...(scroll_offset + visible_height)]

          visible_history.each_with_index do |dir, idx|
            actual_idx = scroll_offset + idx
            setpos(modal_y + 3 + idx, modal_x)
            attron(color_pair(4)) do
              addstr('│ ')
            end

            # Highlight selected
            if actual_idx == selected
              attron(color_pair(3) | Curses::A_BOLD) do
                display_dir = dir.length > modal_width - 6 ? "...#{dir[-(modal_width - 9)..]}" : dir
                addstr(display_dir.ljust(modal_width - 4))
              end
            else
              display_dir = dir.length > modal_width - 6 ? "...#{dir[-(modal_width - 9)..]}" : dir
              addstr(display_dir.ljust(modal_width - 4))
            end

            attron(color_pair(4)) do
              addstr(' │')
            end
          end

          # Fill remaining lines
          (visible_history.length...visible_height).each do |idx|
            setpos(modal_y + 3 + idx, modal_x)
            attron(color_pair(4)) do
              addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
            end
          end

          # Draw footer
          setpos(modal_y + modal_height - 4, modal_x)
          attron(color_pair(4)) do
            addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
          end

          setpos(modal_y + modal_height - 3, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          addstr('↑/↓: Navigate  Enter: Go  ESC: Cancel'.ljust(modal_width - 4))
          attron(color_pair(4)) do
            addstr(' │')
          end

          setpos(modal_y + modal_height - 2, modal_x)
          attron(color_pair(4)) do
            addstr('│ ')
          end
          addstr("#{selected + 1}/#{@directory_history.length}".ljust(modal_width - 4))
          attron(color_pair(4)) do
            addstr(' │')
          end

          setpos(modal_y + modal_height - 1, modal_x)
          attron(color_pair(4)) do
            addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
          end

          refresh

          # Handle input
          ch = getch
          case ch
          when Curses::Key::UP, 'k'
            selected = [selected - 1, 0].max
            scroll_offset = selected if selected < scroll_offset
          when Curses::Key::DOWN, 'j'
            selected = [selected + 1, @directory_history.length - 1].min
            scroll_offset = selected - visible_height + 1 if selected >= scroll_offset + visible_height
          when 10, 13  # Enter
            target_dir = @directory_history[selected]
            if File.directory?(target_dir)
              @current_dir = target_dir
              @selected_index = 0
              @scroll_offset = 0
              force_refresh
            end
            break
          when 27, 'q'  # ESC
            break
          end
        end
      end

      def show_no_history_modal
        max_y = lines
        max_x = cols

        modal_height = 8
        modal_width = 50
        modal_y = (max_y - modal_height) / 2
        modal_x = (max_x - modal_width) / 2

        (modal_y..(modal_y + modal_height)).each do |y|
          setpos(y, modal_x)
          attron(color_pair(3)) do
            addstr(' ' * modal_width)
          end
        end

        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr('No directory history yet.'.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        addstr('Press any key to continue'.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        refresh
        getch
        true
      end
    end
  end
end
