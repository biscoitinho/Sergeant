# frozen_string_literal: true

# File operation modals (preview, edit, paste, delete, rename)

module Sergeant
  module Modals
    module FileOperations
      def edit_file
        item = @items[@selected_index]

        # Only edit files, not directories
        return unless item && item[:type] == :file

        file_path = item[:path]

        # Close curses screen temporarily
        close_screen

        begin
          # Respect user's preferred editor
          editor = ENV['EDITOR'] || ENV['VISUAL']

          if editor
            # Use user's preferred editor
            system("#{editor} \"#{file_path}\"")
          elsif nvim_available?
            # Second fallback: nvim (modern vim)
            system("nvim \"#{file_path}\"")
          elsif nano_available?
            # First fallback: nano (user-friendly)
            system("nano \"#{file_path}\"")
          elsif vim_available?
            # Third fallback: vim
            system("vim \"#{file_path}\"")
          elsif vi_available?
            # Fourth fallback: vi (always available on POSIX)
            system("vi \"#{file_path}\"")
          else
            # This should never happen on POSIX systems
            puts 'No editor found. Please set $EDITOR environment variable.'
            puts 'Press Enter to continue...'
            gets
          end
        rescue StandardError => e
          puts "Error opening editor: #{e.message}"
          puts 'Press Enter to continue...'
          gets
        end

        # Restore curses screen
        init_screen
        if has_colors?
          start_color
          apply_color_theme
        end
        curs_set(0)
        noecho
        stdscr.keypad(true)
      end

      def preview_file
        item = @items[@selected_index]

        # Only preview files, not directories
        return unless item && item[:type] == :file

        file_path = item[:path]

        # Check if it's a text file
        unless text_file?(file_path)
          show_error_modal('Cannot preview: Not a text file or too large (>50MB)')
          return
        end

        # Close curses screen temporarily
        close_screen

        begin
          file_ext = File.extname(file_path).downcase

          # Use glow for markdown files if available, otherwise fall back to less
          if file_ext == '.md' && glow_available?
            system("glow -p \"#{file_path}\"")
          elsif file_ext == '.md'
            system("less -R -F -X \"#{file_path}\"")
          elsif nvim_available?
            # For all other text files, prefer nvim for read-only
            system("nvim -R \"#{file_path}\"")
          elsif vim_available?
            system("vim -R \"#{file_path}\"")
          elsif vi_available?
            system("vi -R \"#{file_path}\"")
          elsif nano_available?
            system("nano -v \"#{file_path}\"")
          else
            # Ultimate fallback to less
            system("less -R -F -X \"#{file_path}\"")
          end
        rescue StandardError => e
          puts "Error previewing file: #{e.message}"
          puts 'Press Enter to continue...'
          gets
        end

        # Restore curses screen
        init_screen
        if has_colors?
          start_color
          apply_color_theme
        end
        curs_set(0)
        noecho
        stdscr.keypad(true)
      end

      def paste_with_modal
        require 'fileutils'

        success_count = 0
        error_count = 0
        errors = []

        @copied_items.each do |source_path|
          next unless File.exist?(source_path)

          filename = File.basename(source_path)
          dest_path = File.join(@current_dir, filename)

          begin
            if File.exist?(dest_path)
              # Handle conflict
              action = ask_conflict_resolution(filename)
              case action
              when :skip
                next
              when :overwrite
                FileUtils.rm_rf(dest_path)
              when :rename
                dest_path = get_unique_filename(dest_path)
              end
            end

            # Perform copy or move
            if @cut_mode
              FileUtils.mv(source_path, dest_path)
            elsif File.directory?(source_path)
              FileUtils.cp_r(source_path, dest_path)
            else
              FileUtils.cp(source_path, dest_path)
            end

            success_count += 1
          rescue StandardError => e
            error_count += 1
            errors << "#{filename}: #{e.message}"
          end
        end

        # Clean up after operation
        @marked_items.clear
        @copied_items.clear
        @cut_mode = false if @cut_mode

        # Show result
        if error_count.positive?
          show_error_modal("Pasted #{success_count}, #{error_count} error(s)")
        else
          show_info_modal("Successfully pasted #{success_count} item(s)")
        end

        # Force refresh to show new files
        force_refresh
      end

      def get_unique_filename(path)
        dir = File.dirname(path)
        basename = File.basename(path, '.*')
        ext = File.extname(path)
        counter = 1

        loop do
          new_path = File.join(dir, "#{basename}_#{counter}#{ext}")
          return new_path unless File.exist?(new_path)

          counter += 1
        end
      end

      def delete_with_modal
        require 'fileutils'

        success_count = 0
        error_count = 0
        errors = []

        @marked_items.each do |item_path|
          next unless File.exist?(item_path)

          begin
            FileUtils.rm_rf(item_path)
            success_count += 1
          rescue StandardError => e
            error_count += 1
            filename = File.basename(item_path)
            errors << "#{filename}: #{e.message}"
          end
        end

        # Clear marked items after deletion
        @marked_items.clear

        # Show result
        if error_count.positive?
          show_error_modal("Deleted #{success_count}, #{error_count} error(s)")
        else
          show_info_modal("Successfully deleted #{success_count} item(s)")
        end

        # Force refresh to show changes
        force_refresh
      end

      def rename_with_modal(item)
        require 'fileutils'

        max_y = lines
        max_x = cols

        modal_height = 8
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
          addstr(' Rename '.center(modal_width - 2))
        end
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('│')
        end

        setpos(modal_y + 2, modal_x)
        attron(color_pair(4)) do
          addstr("\u251C#{'─' * (modal_width - 2)}\u2524")
        end

        msg = "Current: #{item[:name]}"
        setpos(modal_y + 3, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        display_msg = msg.length > modal_width - 4 ? "#{msg[0..(modal_width - 8)]}..." : msg
        addstr(display_msg.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 4, modal_x)
        attron(color_pair(4)) do
          addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
        end

        setpos(modal_y + 5, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end
        prompt = 'New name: '
        attron(color_pair(5)) do
          addstr(prompt)
        end
        addstr(' ' * (modal_width - 4 - prompt.length))
        attron(color_pair(4)) do
          addstr(' │')
        end

        setpos(modal_y + 6, modal_x)
        attron(color_pair(4)) do
          addstr('│ ')
        end

        curs_set(1)
        echo
        setpos(modal_y + 6, modal_x + 2)

        input_width = modal_width - 5
        new_name = item[:name].dup

        # Position cursor at end of name
        setpos(modal_y + 6, modal_x + 2)
        addstr(new_name.ljust(input_width))
        setpos(modal_y + 6, modal_x + 2 + new_name.length)

        loop do
          ch = getch

          case ch
          when 10, 13
            break
          when 27
            new_name = ''
            break
          when 127, Curses::Key::BACKSPACE
            if new_name.length.positive?
              new_name = new_name[0...-1]
              setpos(modal_y + 6, modal_x + 2)
              addstr(new_name.ljust(input_width))
              setpos(modal_y + 6, modal_x + 2 + new_name.length)
            end
          else
            if ch.is_a?(String) && new_name.length < input_width && ch != '/'
              new_name += ch
              setpos(modal_y + 6, modal_x + 2)
              addstr(new_name.ljust(input_width))
              setpos(modal_y + 6, modal_x + 2 + new_name.length)
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

        new_name = new_name.strip

        return if new_name.empty? || new_name == item[:name]

        old_path = item[:path]
        new_path = File.join(File.dirname(old_path), new_name)

        if File.exist?(new_path)
          show_error_modal('File or directory already exists!')
        else
          begin
            FileUtils.mv(old_path, new_path)
            show_info_modal('Renamed successfully!')

            # Update marked items if this item was marked
            if @marked_items.include?(old_path)
              @marked_items.delete(old_path)
              @marked_items << new_path
            end

            # Update copied items if this item was copied
            if @copied_items.include?(old_path)
              @copied_items.delete(old_path)
              @copied_items << new_path
            end

            # Force refresh to show renamed item
            force_refresh
          rescue StandardError => e
            show_error_modal("Error: #{e.message}")
          end
        end
      end

      def create_new_with_modal
        max_y = lines
        max_x = cols

        modal_width = [60, max_x - 4].min
        modal_height = [10, max_y - 8].min  # Adaptive height (more conservative margin)
        modal_x = (max_x - modal_width) / 2
        modal_y = (max_y - modal_height) / 2

        # Draw modal box
        setpos(modal_y, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
        end

        (1...modal_height - 1).each do |i|
          setpos(modal_y + i, modal_x)
          attron(color_pair(4) | Curses::A_BOLD) do
            addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
          end
        end

        # Bottom border
        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        # Title
        setpos(modal_y + 1, modal_x + 2)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('Create New')
        end

        # Prompt
        setpos(modal_y + 3, modal_x + 2)
        addstr('What do you want to create?')

        setpos(modal_y + 5, modal_x + 2)
        attron(color_pair(1) | Curses::A_BOLD) do
          addstr('[f] File    [d] Directory    [ESC] Cancel')
        end

        refresh

        # Get choice
        choice = getch
        return if choice == 27 # ESC

        create_type = case choice
                      when 'f', 'F'
                        :file
                      when 'd', 'D'
                        :directory
                      else
                        return
                      end

        # Clear and ask for name
        setpos(modal_y + 3, modal_x + 2)
        addstr(' ' * (modal_width - 4))
        setpos(modal_y + 5, modal_x + 2)
        addstr(' ' * (modal_width - 4))

        setpos(modal_y + 3, modal_x + 2)
        type_text = create_type == :file ? 'file' : 'directory'
        addstr("Enter #{type_text} name:")

        setpos(modal_y + 5, modal_x + 2)
        addstr('(ESC to cancel)')

        # Input field
        input_width = modal_width - 6
        setpos(modal_y + 6, modal_x + 2)
        attron(color_pair(3)) do
          addstr(' ' * input_width)
        end

        # Get input
        echo
        curs_set(1)
        new_name = ''

        loop do
          setpos(modal_y + 6, modal_x + 2 + new_name.length)
          refresh

          ch = getch

          case ch
          when 10, 13
            break
          when 27
            new_name = ''
            break
          when 127, Curses::Key::BACKSPACE
            if new_name.length.positive?
              new_name = new_name[0...-1]
              setpos(modal_y + 6, modal_x + 2)
              addstr(new_name.ljust(input_width))
              setpos(modal_y + 6, modal_x + 2 + new_name.length)
            end
          else
            if ch.is_a?(String) && new_name.length < input_width && ch != '/'
              new_name += ch
              setpos(modal_y + 6, modal_x + 2)
              addstr(new_name.ljust(input_width))
              setpos(modal_y + 6, modal_x + 2 + new_name.length)
            end
          end
        end

        noecho
        curs_set(0)

        new_name = new_name.strip

        return if new_name.empty?

        new_path = File.join(@current_dir, new_name)

        if File.exist?(new_path)
          show_error_modal('File or directory already exists!')
        else
          begin
            if create_type == :file
              FileUtils.touch(new_path)
              show_info_modal('File created successfully!')
            else
              FileUtils.mkdir_p(new_path)
              show_info_modal('Directory created successfully!')
            end

            # Force refresh to show new item
            force_refresh
          rescue StandardError => e
            show_error_modal("Error: #{e.message}")
          end
        end
      end

      def execute_terminal_command
        max_y = lines
        max_x = cols

        modal_width = [80, max_x - 4].min
        modal_height = [8, max_y - 8].min  # Adaptive height (more conservative margin)
        modal_x = (max_x - modal_width) / 2
        modal_y = (max_y - modal_height) / 2

        # Draw modal box
        setpos(modal_y, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u250C#{'─' * (modal_width - 2)}\u2510")
        end

        (1...modal_height - 1).each do |i|
          setpos(modal_y + i, modal_x)
          attron(color_pair(4) | Curses::A_BOLD) do
            addstr("\u2502#{' ' * (modal_width - 2)}\u2502")
          end
        end

        # Bottom border
        setpos(modal_y + modal_height - 1, modal_x)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr("\u2514#{'─' * (modal_width - 2)}\u2518")
        end

        # Title
        setpos(modal_y + 1, modal_x + 2)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('Execute Terminal Command')
        end

        # Show current directory
        setpos(modal_y + 2, modal_x + 2)
        attron(color_pair(5)) do
          dir_display = @current_dir
          max_dir_len = modal_width - 8
          dir_display = "...#{@current_dir[(-max_dir_len + 3)..]}" if @current_dir.length > max_dir_len
          addstr("in: #{dir_display}")
        end

        # Prompt
        setpos(modal_y + 4, modal_x + 2)
        addstr(':')

        # Input field
        input_width = modal_width - 6
        setpos(modal_y + 4, modal_x + 4)
        attron(color_pair(3)) do
          addstr(' ' * input_width)
        end

        setpos(modal_y + 6, modal_x + 2)
        addstr('(ESC to cancel)')

        # Get input
        echo
        curs_set(1)
        command = ''

        loop do
          setpos(modal_y + 4, modal_x + 4 + command.length)
          refresh

          ch = getch

          case ch
          when 10, 13
            break
          when 27
            command = ''
            break
          when 127, Curses::Key::BACKSPACE
            if command.length.positive?
              command = command[0...-1]
              setpos(modal_y + 4, modal_x + 4)
              addstr(command.ljust(input_width))
              setpos(modal_y + 4, modal_x + 4 + command.length)
            end
          else
            if ch.is_a?(String) && command.length < input_width
              command += ch
              setpos(modal_y + 4, modal_x + 4)
              addstr(command.ljust(input_width))
              setpos(modal_y + 4, modal_x + 4 + command.length)
            end
          end
        end

        noecho
        curs_set(0)

        command = command.strip

        return if command.empty?

        # Close curses and execute command
        close_screen

        puts "Executing: #{command}"
        puts '─' * 80
        puts

        begin
          # Change to current directory and execute
          Dir.chdir(@current_dir) do
            system(command)
          end
        rescue StandardError => e
          puts
          puts "Error: #{e.message}"
        end

        puts
        puts '─' * 80
        puts 'Press Enter to continue...'
        gets

        # Restore curses
        init_screen
        if has_colors?
          start_color
          apply_color_theme
        end
        curs_set(0)
        noecho
        stdscr.keypad(true)

        # Force refresh to show any changes from the command
        force_refresh
      end
    end
  end
end
