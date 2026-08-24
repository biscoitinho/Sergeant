# frozen_string_literal: true

# UI rendering methods

module Sergeant
  module Rendering
    # Use ASCII icons on Windows for better terminal compatibility
    WINDOWS = Gem.win_platform?
    ICON_DIR = WINDOWS ? '[D] ' : '📁 '
    ICON_FILE = WINDOWS ? '[F] ' : '📄 '
    ICON_MARK = WINDOWS ? '* ' : '✓ '
    ICON_SELECT = WINDOWS ? '> ' : '▶ '

    # Side preview panel only kicks in once the terminal is wide enough that
    # both panes stay readable; below that it just doesn't fit.
    MIN_PREVIEW_TOTAL_WIDTH = 100
    MIN_PREVIEW_WIDTH = 24
    PREVIEW_WIDTH_RATIO_DEFAULT = 0.35
    PREVIEW_WIDTH_RATIO_MIN = 0.15
    PREVIEW_WIDTH_RATIO_MAX = 0.6
    PREVIEW_WIDTH_RATIO_STEP = 0.05

    # Maps file_category (Sergeant::Utils) to the color pair set up in
    # Sergeant#apply_color_theme (pairs 7-10).
    FILE_CATEGORY_COLOR_PAIRS = {
      archive: 7,
      media: 8,
      code: 9,
      executable: 10
    }.freeze

    # Maps token_category (Sergeant::Utils) to the syntax-highlight color
    # pairs set up in Sergeant#apply_color_theme (pairs 11-16).
    PREVIEW_TOKEN_COLOR_PAIRS = {
      keyword: 11,
      string: 12,
      comment: 13,
      number: 14,
      function: 15,
      constant: 15,
      error: 16
    }.freeze

    def draw_screen
      # `erase` only rewrites the virtual buffer; `refresh` then diffs it
      # against the physical screen and repaints just the changed cells.
      # `clear` forces a full physical blank-then-redraw on every call,
      # which flickers visibly on fast terminals like Alacritty.
      erase

      max_y = lines - 1
      max_x = cols

      preview_enabled = @show_preview && max_x >= MIN_PREVIEW_TOTAL_WIDTH
      if preview_enabled
        preview_width = [(max_x * @preview_width_ratio).to_i, MIN_PREVIEW_WIDTH].max
        list_width = max_x - preview_width - 1
      else
        preview_width = 0
        list_width = max_x
      end

      setpos(0, 0)
      attron(color_pair(4) | Curses::A_BOLD) do
        addstr("┌─ Sergeant - 'Leave it to the Sarge!' ".ljust(max_x, '─'))
      end

      setpos(1, 0)
      branch = get_git_branch

      # Build status info
      status_parts = []
      unless @marked_items.empty?
        total_size = @marked_items.sum { |path| File.size(path) rescue 0 }
        size_str = format_size(total_size)
        status_parts << "Marked: #{@marked_items.length} (#{size_str.strip})"
      end
      unless @copied_items.empty?
        mode_text = @cut_mode ? 'Cut' : 'Copied'
        status_parts << "#{mode_text}: #{@copied_items.length}"
      end
      unless @filter_text.empty?
        filtered_count = @items.length - (@items.any? { |i| i[:name] == '..' } ? 1 : 0)
        status_parts << "Filter: '#{@filter_text}' (#{filtered_count})"
      end
      status_text = status_parts.empty? ? '' : " | #{status_parts.join(' | ')}"

      status_width = list_width

      if branch
        branch_text = " [#{branch}]"
        path_max_length = status_width - 4 - branch_text.length - status_text.length
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
        remaining = status_width - 2 - path_display.length - branch_text.length - status_text.length
      else
        path_max_length = status_width - 4 - status_text.length
        path_display = @current_dir.length > path_max_length ? "...#{@current_dir[(-path_max_length + 3)..]}" : @current_dir

        attron(color_pair(5)) do
          addstr("│ #{path_display}")
        end
        unless status_text.empty?
          attron(color_pair(1) | Curses::A_BOLD) do
            addstr(status_text)
          end
        end
        remaining = status_width - 2 - path_display.length - status_text.length
      end
      addstr(''.ljust(remaining)) if remaining.positive?

      setpos(2, 0)
      attron(color_pair(4)) do
        addstr('├'.ljust(max_x, '─'))
      end

      setpos(max_y, 0)
      attron(color_pair(4)) do
        help = '↑↓/jk:Move  Enter:Open  ←h:Back  Space:Mark  c:Copy  x:Cut  p:Paste  d:Del  e:Edit  m:Help  q:Quit'
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

        attron(item_attributes(item, is_selected)) do
          draw_item(item, list_width, is_selected)
        end
      end

      if @items.length > visible_lines
        total = @items.length
        visible = visible_lines
        scroll_pos = (@scroll_offset.to_f / (total - visible)) * (visible - 1)
        scroll_pos = scroll_pos.round.clamp(0, visible - 1)

        setpos(3 + scroll_pos, list_width - 1)
        attron(color_pair(4) | Curses::A_BOLD) do
          addstr('█')
        end
      end

      draw_preview_panel(list_width, preview_width, max_y, visible_lines) if preview_enabled

      refresh
    end

    # Which curses attributes to draw a list row with: selection highlight
    # wins, then directories, then a file's type-based color (falling back
    # to the plain dimmed file color when its category has none).
    def item_attributes(item, is_selected)
      return color_pair(3) | Curses::A_BOLD if is_selected
      return color_pair(1) if item[:type] == :directory

      pair = FILE_CATEGORY_COLOR_PAIRS[file_category(item)]
      pair ? color_pair(pair) : (color_pair(2) | Curses::A_DIM)
    end

    def draw_item(item, max_x, is_selected)
      icon = item[:type] == :directory ? ICON_DIR : ICON_FILE

      # Check if item is marked
      is_marked = @marked_items.include?(item[:path])
      mark_indicator = is_marked ? ICON_MARK : '  '

      prefix = is_selected ? ICON_SELECT : '  '

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

    # Draws the divider, title row and content of the side preview panel.
    # Content itself is precomputed by Sergeant#update_preview_if_needed -
    # this method only ever paints what's already in @preview_lines, so it
    # stays cheap even though draw_screen runs on every keystroke.
    def draw_preview_panel(list_width, preview_width, max_y, visible_lines)
      col = list_width + 1
      width = preview_width - 1
      return if width <= 1

      draw_preview_divider(list_width, max_y)
      draw_preview_title(col, width)

      case @preview_kind
      when :text
        if @preview_lines.empty?
          draw_preview_message(col, width, '(empty file)')
        else
          draw_preview_highlighted_lines(col, width, visible_lines, @preview_lines)
        end
      when :directory
        if @preview_lines.empty?
          draw_preview_message(col, width, '(empty directory)')
        else
          names = @preview_lines.map { |name| "  #{name}" }
          draw_preview_lines(col, width, visible_lines, names, color_pair(1))
        end
      else
        draw_preview_message(col, width, preview_placeholder_message)
      end
    end

    def draw_preview_divider(list_width, max_y)
      setpos(0, list_width)
      attron(color_pair(4) | Curses::A_BOLD) { addstr('┬') }

      (1...max_y).each do |row|
        next if row == 2

        setpos(row, list_width)
        attron(color_pair(4)) { addstr('│') }
      end

      setpos(2, list_width)
      attron(color_pair(4)) { addstr('┼') }
    end

    def draw_preview_title(col, width)
      label = case @preview_kind
              when :directory then "#{ICON_DIR}#{@preview_item[:name]}"
              when :text, :binary then "#{ICON_FILE}#{@preview_item[:name]}"
              else ''
              end

      setpos(1, col)
      attron(color_pair(5) | Curses::A_BOLD) do
        addstr(truncate_for_preview(label, width).ljust(width))
      end
    end

    def draw_preview_lines(col, width, visible_lines, source_lines, pair)
      visible_lines.times do |idx|
        setpos(idx + 3, col)
        line = source_lines[idx]
        attron(pair) do
          addstr((line ? truncate_for_preview(line, width) : '').ljust(width))
        end
      end
    end

    # Like draw_preview_lines, but each line is an array of
    # {text:, category:} segments (built by Sergeant#build_text_preview via
    # Rouge) instead of a single string, so every token can carry its own
    # syntax-highlight color.
    def draw_preview_highlighted_lines(col, width, visible_lines, lines)
      visible_lines.times do |idx|
        setpos(idx + 3, col)
        draw_preview_segments(lines[idx] || [], width)
      end
    end

    def draw_preview_segments(segments, width)
      remaining = width

      segments.each do |segment|
        break if remaining <= 0

        text = segment[:text]
        chunk = text.length > remaining ? text[0, remaining] : text

        attron(preview_token_attr(segment[:category])) { addstr(chunk) }
        remaining -= chunk.length
      end

      attron(color_pair(2)) { addstr(' ' * remaining) } if remaining.positive?
    end

    def preview_token_attr(category)
      color_pair(PREVIEW_TOKEN_COLOR_PAIRS[category] || 2)
    end

    def draw_preview_message(col, width, message)
      setpos(3, col)
      attron(color_pair(2) | Curses::A_DIM) do
        addstr(truncate_for_preview(message, width).ljust(width))
      end
    end

    def truncate_for_preview(text, width)
      return text if text.length <= width
      return text[0, width].to_s if width <= 1

      "#{text[0, width - 1]}…"
    end

    def preview_placeholder_message
      case @preview_kind
      when :empty then '(empty directory)'
      when :binary
        size = @preview_item && @preview_item[:size]
        size ? "(no preview - #{format_size(size).strip})" : '(no preview available)'
      else
        ''
      end
    end
  end
end
