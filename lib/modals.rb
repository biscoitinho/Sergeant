# Modal dialog windows

module Sergeant
  module Modals
    def goto_bookmark
      return if @bookmarks.empty? && show_no_bookmarks_modal

      max_y = lines
      max_x = cols
      
      modal_height = [@bookmarks.length + 8, max_y - 4].min
      modal_width = [60, max_x - 4].min
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2
      
      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end
      
      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end
      
      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        title = " Bookmarks ".center(modal_width - 2)
        addstr(title)
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      
      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end
      
      visible_bookmarks = @bookmarks.to_a.first(modal_height - 7)
      visible_bookmarks.each_with_index do |(name, path), idx|
        setpos(modal_y + 3 + idx, modal_x)
        attron(color_pair(4)) do
          addstr("│")
        end
        
        attron(color_pair(1) | Curses::A_BOLD) do
          addstr(" #{name}".ljust(20))
        end
        
        path_space = modal_width - 23
        display_path = path.length > path_space ? "...#{path[-(path_space-3)..-1]}" : path
        addstr(display_path.ljust(path_space - 1))
        
        attron(color_pair(4)) do
          addstr("│")
        end
      end
      
      (visible_bookmarks.length...modal_height - 7).each do |idx|
        setpos(modal_y + 3 + idx, modal_x)
        attron(color_pair(4)) do
          addstr("│" + " " * (modal_width - 2) + "│")
        end
      end
      
      input_line = modal_y + modal_height - 4
      setpos(input_line, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end
      
      setpos(input_line + 1, modal_x)
      attron(color_pair(4)) do
        addstr("│")
      end
      prompt = " Enter bookmark name: "
      attron(color_pair(5)) do
        addstr(prompt)
      end
      addstr(" " * (modal_width - 2 - prompt.length))
      attron(color_pair(4)) do
        addstr("│")
      end
      
      setpos(input_line + 2, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      
      curs_set(1)
      echo
      setpos(input_line + 2, modal_x + 2)
      
      input_width = modal_width - 5
      bookmark_name = ""
      
      loop do
        ch = getch
        
        case ch
        when 10, 13
          break
        when 27
          bookmark_name = ""
          break
        when 127, Curses::Key::BACKSPACE
          if bookmark_name.length > 0
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
        addstr("└" + "─" * (modal_width - 2) + "┘")
      end
      
      refresh
      
      bookmark_name = bookmark_name.strip
      
      unless bookmark_name.empty?
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
    end

    def show_no_bookmarks_modal
      max_y = lines
      max_x = cols
      
      modal_height = 10
      modal_width = 60
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2
      
      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end
      
      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end
      
      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(" No Bookmarks Defined ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      
      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end
      
      messages = [
        "Add bookmarks to ~/.sgtrc:",
        "",
        "[bookmarks]",
        "home=/home/user",
        "projects=~/projects",
      ]
      
      messages.each_with_index do |msg, idx|
        setpos(modal_y + 3 + idx, modal_x)
        attron(color_pair(4)) do
          addstr("│ ")
        end
        if idx > 1
          attron(color_pair(1)) do
            addstr(msg.ljust(modal_width - 4))
          end
        else
          addstr(msg.ljust(modal_width - 4))
        end
        attron(color_pair(4)) do
          addstr(" │")
        end
      end
      
      setpos(modal_y + 9, modal_x)
      attron(color_pair(4)) do
        addstr("│")
      end
      attron(color_pair(4) | Curses::A_DIM) do
        addstr(" Press any key to continue ".center(modal_width - 2))
      end
      attron(color_pair(4)) do
        addstr("│")
      end
      
      setpos(modal_y + modal_height - 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("└" + "─" * (modal_width - 2) + "┘")
      end
      
      refresh
      getch
      true
    end

    def show_error_modal(message)
      max_y = lines
      max_x = cols
      
      modal_height = 7
      modal_width = [message.length + 10, 50].max
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2
      
      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end
      
      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end
      
      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr(" Error ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      
      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end
      
      setpos(modal_y + 3, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      addstr(message.center(modal_width - 4))
      attron(color_pair(4)) do
        addstr(" │")
      end
      
      setpos(modal_y + 4, modal_x)
      attron(color_pair(4)) do
        addstr("│" + " " * (modal_width - 2) + "│")
      end
      
      setpos(modal_y + 5, modal_x)
      attron(color_pair(4)) do
        addstr("│")
      end
      attron(color_pair(4) | Curses::A_DIM) do
        addstr(" Press any key to continue ".center(modal_width - 2))
      end
      attron(color_pair(4)) do
        addstr("│")
      end
      
      setpos(modal_y + modal_height - 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("└" + "─" * (modal_width - 2) + "┘")
      end
      
      refresh
      getch
    end

    def preview_file
      item = @items[@selected_index]

      # Only preview files, not directories
      return unless item && item[:type] == :file

      file_path = item[:path]

      # Check if it's a text file
      unless text_file?(file_path)
        show_error_modal("Cannot preview: Not a text file or too large (>50MB)")
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
        else
          # For all other text files, use vim/vi/nano
          if vim_available?
            system("vim -R \"#{file_path}\"")
          elsif vi_available?
            system("vi -R \"#{file_path}\"")
          elsif nano_available?
            system("nano -v \"#{file_path}\"")
          else
            # Ultimate fallback to less
            system("less -R -F -X \"#{file_path}\"")
          end
        end
      rescue => e
        puts "Error previewing file: #{e.message}"
        puts "Press Enter to continue..."
        gets
      end

      # Restore curses screen
      init_screen
      start_color
      curs_set(0)
      noecho
      stdscr.keypad(true)
      apply_color_theme
    end

    def show_info_modal(message)
      max_y = lines
      max_x = cols

      modal_height = 7
      modal_width = [message.length + 10, 50].max
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2

      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end

      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end

      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(" Info ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end

      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end

      setpos(modal_y + 3, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      addstr(message.center(modal_width - 4))
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 4, modal_x)
      attron(color_pair(4)) do
        addstr("│" + " " * (modal_width - 2) + "│")
      end

      setpos(modal_y + 5, modal_x)
      attron(color_pair(4)) do
        addstr("│")
      end
      attron(color_pair(4) | Curses::A_DIM) do
        addstr(" Press any key to continue ".center(modal_width - 2))
      end
      attron(color_pair(4)) do
        addstr("│")
      end

      setpos(modal_y + modal_height - 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("└" + "─" * (modal_width - 2) + "┘")
      end

      refresh
      getch
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
          else
            if File.directory?(source_path)
              FileUtils.cp_r(source_path, dest_path)
            else
              FileUtils.cp(source_path, dest_path)
            end
          end

          success_count += 1
        rescue => e
          error_count += 1
          errors << "#{filename}: #{e.message}"
        end
      end

      # Clean up after cut operation
      if @cut_mode
        @marked_items.clear
        @copied_items.clear
        @cut_mode = false
      else
        # For copy, clear marks after paste
        @marked_items.clear
        @copied_items.clear
      end

      # Show result
      if error_count > 0
        show_error_modal("Pasted #{success_count}, #{error_count} error(s)")
      else
        show_info_modal("Successfully pasted #{success_count} item(s)")
      end
    end

    def ask_conflict_resolution(filename)
      max_y = lines
      max_x = cols

      modal_height = 10
      modal_width = [filename.length + 30, 60].min
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2

      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end

      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end

      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(" File Conflict ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end

      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end

      msg = "File already exists:"
      setpos(modal_y + 3, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      addstr(msg.ljust(modal_width - 4))
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 4, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      attron(color_pair(1) | Curses::A_BOLD) do
        display_name = filename.length > modal_width - 6 ? "#{filename[0..modal_width-10]}..." : filename
        addstr(display_name.ljust(modal_width - 4))
      end
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 5, modal_x)
      attron(color_pair(4)) do
        addstr("│" + " " * (modal_width - 2) + "│")
      end

      options = [
        "s - Skip",
        "o - Overwrite",
        "r - Rename"
      ]

      options.each_with_index do |opt, idx|
        setpos(modal_y + 6 + idx, modal_x)
        attron(color_pair(4)) do
          addstr("│ ")
        end
        addstr(opt.ljust(modal_width - 4))
        attron(color_pair(4)) do
          addstr(" │")
        end
      end

      setpos(modal_y + modal_height - 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("└" + "─" * (modal_width - 2) + "┘")
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

    def get_unique_filename(path)
      dir = File.dirname(path)
      basename = File.basename(path, ".*")
      ext = File.extname(path)
      counter = 1

      loop do
        new_path = File.join(dir, "#{basename}_#{counter}#{ext}")
        return new_path unless File.exist?(new_path)
        counter += 1
      end
    end

    def confirm_delete_modal(count)
      max_y = lines
      max_x = cols

      modal_height = 9
      modal_width = 60
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2

      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end

      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end

      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(" Confirm Delete ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end

      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end

      msg1 = "Delete #{count} item(s) permanently?"
      setpos(modal_y + 3, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      addstr(msg1.center(modal_width - 4))
      attron(color_pair(4)) do
        addstr(" │")
      end

      msg2 = "This action cannot be undone!"
      setpos(modal_y + 4, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      attron(Curses::A_BOLD) do
        addstr(msg2.center(modal_width - 4))
      end
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 5, modal_x)
      attron(color_pair(4)) do
        addstr("│" + " " * (modal_width - 2) + "│")
      end

      options = [
        "y - Yes, delete",
        "n - No, cancel"
      ]

      options.each_with_index do |opt, idx|
        setpos(modal_y + 6 + idx, modal_x)
        attron(color_pair(4)) do
          addstr("│ ")
        end
        addstr(opt.center(modal_width - 4))
        attron(color_pair(4)) do
          addstr(" │")
        end
      end

      setpos(modal_y + modal_height - 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("└" + "─" * (modal_width - 2) + "┘")
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
        rescue => e
          error_count += 1
          filename = File.basename(item_path)
          errors << "#{filename}: #{e.message}"
        end
      end

      # Clear marked items after deletion
      @marked_items.clear

      # Show result
      if error_count > 0
        show_error_modal("Deleted #{success_count}, #{error_count} error(s)")
      else
        show_info_modal("Successfully deleted #{success_count} item(s)")
      end
    end
        def rename_with_modal(item)
      require 'fileutils'

      max_y = lines
      max_x = cols

      modal_height = 8
      modal_width = 70
      modal_y = (max_y - modal_height) / 2
      modal_x = (max_x - modal_width) / 2

      (modal_y..modal_y + modal_height).each do |y|
        setpos(y, modal_x)
        attron(color_pair(3)) do
          addstr(" " * modal_width)
        end
      end

      setpos(modal_y, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌" + "─" * (modal_width - 2) + "┐")
      end

      setpos(modal_y + 1, modal_x)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(" Rename ".center(modal_width - 2))
      end
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("│")
      end

      setpos(modal_y + 2, modal_x)
      attron(color_pair(4)) do
        addstr("├" + "─" * (modal_width - 2) + "┤")
      end

      msg = "Current: #{item[:name]}"
      setpos(modal_y + 3, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      display_msg = msg.length > modal_width - 4 ? "#{msg[0..modal_width-8]}..." : msg
      addstr(display_msg.ljust(modal_width - 4))
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 4, modal_x)
      attron(color_pair(4)) do
        addstr("│" + " " * (modal_width - 2) + "│")
      end

      setpos(modal_y + 5, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
      end
      prompt = "New name: "
      attron(color_pair(5)) do
        addstr(prompt)
      end
      addstr(" " * (modal_width - 4 - prompt.length))
      attron(color_pair(4)) do
        addstr(" │")
      end

      setpos(modal_y + 6, modal_x)
      attron(color_pair(4)) do
        addstr("│ ")
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
          new_name = ""
          break
        when 127, Curses::Key::BACKSPACE
          if new_name.length > 0
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
        addstr("└" + "─" * (modal_width - 2) + "┘")
      end

      refresh

      new_name = new_name.strip

      unless new_name.empty? || new_name == item[:name]
        old_path = item[:path]
        new_path = File.join(File.dirname(old_path), new_name)

        if File.exist?(new_path)
          show_error_modal("File or directory already exists!")
        else
          begin
            FileUtils.mv(old_path, new_path)
            show_info_modal("Renamed successfully!")

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
          rescue => e
            show_error_modal("Error: #{e.message}")
          end
        end
      end
    end
  end
end

