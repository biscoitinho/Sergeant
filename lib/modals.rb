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
  end
end

