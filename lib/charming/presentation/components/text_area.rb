# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      # TextArea is a multi-line text editor component. Supports character insertion (with
      # newline insertion via Shift+Enter or Ctrl+J), cursor movement (left/right/up/down,
      # home/end, page up/down), deletion (backspace/delete), and scrolling for long buffers.
      # Vertical movement preserves a "preferred column" so left/right navigation feels stable.
      class TextArea < Component
        # The current text value, cursor byte offset, top-visible row offset, and remembered
        # column for vertical navigation, respectively.
        attr_reader :value, :cursor, :offset, :preferred_column

        # *value* is the initial text. *placeholder* is shown when the value is empty. *width* and
        # *height* constrain the rendered output. *cursor* defaults to the end of the value.
        # *offset* is the top-visible row. *preferred_column* is the column to resume at on
        # vertical movement (defaults to the current column on first use).
        def initialize(value: "", placeholder: "", width: nil, height: nil, cursor: nil, offset: 0, preferred_column: nil)
          super()
          @value = value.dup
          @placeholder = placeholder
          @width = width
          @height = height
          @cursor = cursor || @value.length
          @offset = offset
          @preferred_column = preferred_column
          clamp_position
          ensure_cursor_visible
        end

        # Routes key events to the appropriate cursor/text mutation. Returns :handled when the
        # event was consumed, nil otherwise.
        def handle_key(event)
          key = Charming.key_of(event)
          return :handled if newline_event?(event) && insert("\n")
          return :handled if character_event?(event) && insert(event.char)

          case key
          when :left then move_left
          when :right then move_right
          when :up then move_up
          when :down then move_down
          when :home then move_home
          when :end then move_end
          when :backspace then delete_before_cursor
          when :delete then delete_at_cursor
          when :page_up then page_up
          when :page_down then page_down
          else return nil
          end

          :handled
        end

        # Renders the visible portion of the text buffer (scrolled to `offset`), with each
        # visible line either clipped to `width` or padded to it.
        def render
          visible_lines.map { |line| render_line(line) }.join("\n")
        end

        private

        attr_reader :placeholder, :width, :height

        # True when the event represents an explicit newline request: Shift+Enter or Ctrl+J.
        def newline_event?(event)
          key = Charming.key_of(event)
          return true if key == :enter && event.respond_to?(:shift) && event.shift
          return true if key == :j && event.respond_to?(:ctrl) && event.ctrl

          false
        end

        # True when *event* carries a single printable character.
        def character_event?(event)
          event.respond_to?(:char) && event.char && event.char.length == 1 && printable?(event.char)
        end

        # True when *char* is not a control character.
        def printable?(char)
          !char.match?(/[[:cntrl:]]/)
        end

        # Inserts *text* at the cursor, advances the cursor by its length, resets the preferred
        # column, and ensures the cursor remains visible.
        def insert(text)
          @value = value[0...cursor].to_s + text + value[cursor..].to_s
          @cursor += text.length
          reset_preferred_column
          ensure_cursor_visible
        end

        # Moves the cursor one character left.
        def move_left
          @cursor -= 1 if cursor.positive?
          reset_preferred_column
          ensure_cursor_visible
        end

        # Moves the cursor one character right.
        def move_right
          @cursor += 1 if cursor < value.length
          reset_preferred_column
          ensure_cursor_visible
        end

        # Moves the cursor up one line while preserving the preferred column.
        def move_up
          move_vertical(-1)
        end

        # Moves the cursor down one line while preserving the preferred column.
        def move_down
          move_vertical(+1)
        end

        # Moves the cursor to the start of the current line.
        def move_home
          row, = cursor_position
          @cursor = line_start(row)
          reset_preferred_column
          ensure_cursor_visible
        end

        # Moves the cursor to the end of the current line.
        def move_end
          row, = cursor_position
          @cursor = line_start(row) + line_length(row)
          reset_preferred_column
          ensure_cursor_visible
        end

        # Deletes the character before the cursor (backspace behavior).
        def delete_before_cursor
          return if cursor.zero?

          @value = value[0...(cursor - 1)].to_s + value[cursor..].to_s
          @cursor -= 1
          reset_preferred_column
          ensure_cursor_visible
        end

        # Deletes the character at the cursor (delete-key behavior).
        def delete_at_cursor
          return if cursor >= value.length

          @value = value[0...cursor].to_s + value[(cursor + 1)..].to_s
          reset_preferred_column
          ensure_cursor_visible
        end

        # Scrolls the buffer up by one viewport height.
        def page_up
          @offset -= viewport_height
          clamp_offset
        end

        # Scrolls the buffer down by one viewport height.
        def page_down
          @offset += viewport_height
          clamp_offset
        end

        # Moves the cursor vertically by *delta* rows. Stays within the line count and uses
        # `preferred_column` so up/down movement feels stable on short lines.
        def move_vertical(delta)
          row, column = cursor_position
          target_row = (row + delta).clamp(0, lines.length - 1)
          @preferred_column ||= column
          @cursor = line_start(target_row) + [@preferred_column, line_length(target_row)].min
          ensure_cursor_visible
        end

        # Sets the preferred column to the current column (called when horizontal movement happens).
        def reset_preferred_column
          @preferred_column = cursor_position.last
        end

        # Returns the cursor's current position as `[row, column]`, where row is the zero-based
        # line index and column is the character offset within that line.
        def cursor_position
          before = value[0...cursor].to_s
          row = before.count("\n")
          last_newline = before.rindex("\n")
          column = last_newline ? before.length - last_newline - 1 : before.length
          [row, column]
        end

        # Returns the byte offset where line *row* begins in the value.
        def line_start(row)
          lines.first(row).sum(&:length) + row
        end

        # Returns the character length of the line at *row* (empty string when row is past the end).
        def line_length(row)
          lines.fetch(row, "").length
        end

        # Splits the value into an array of lines (preserving trailing empty lines).
        def lines
          value.empty? ? [""] : value.split("\n", -1)
        end

        # Returns the rendered lines (with cursor marker inserted) before viewport slicing.
        def rendered_lines
          return [cursor_marker + placeholder] if value.empty?

          (value[0...cursor].to_s + cursor_marker + value[cursor..].to_s).split("\n", -1)
        end

        # Returns the lines that should be visible in the current viewport, padded to *height*
        # with empty strings when the buffer is shorter.
        def visible_lines
          ensure_cursor_visible
          rendered = rendered_lines.slice(offset, viewport_height) || []
          return rendered unless height

          rendered + Array.new([height - rendered.length, 0].max, "")
        end

        # Renders a single line, clipping to *width* and padding with spaces.
        def render_line(line)
          return line unless width

          clipped = UI.visible_slice(line, 0, width)
          clipped + (" " * [width - UI::Width.measure(clipped), 0].max)
        end

        # Adjusts the top-visible offset so the cursor row is in view. Scrolling is performed
        # one row at a time when needed.
        def ensure_cursor_visible
          row, = cursor_position
          @offset = row if row < offset
          @offset = row - viewport_height + 1 if row >= offset + viewport_height
          clamp_offset
        end

        # Clamps the cursor and offset to valid bounds.
        def clamp_position
          @cursor = cursor.clamp(0, value.length)
          clamp_offset
        end

        # Clamps the offset to the valid range `[0, max_offset]`.
        def clamp_offset
          @offset = offset.clamp(0, max_offset)
        end

        # Returns the maximum allowed offset (so the bottom of the buffer is reachable).
        def max_offset
          [lines.length - viewport_height, 0].max
        end

        # Returns the visible row count (the configured *height* or the buffer's line count).
        def viewport_height
          height || lines.length
        end

        # The literal character used to mark the cursor position in `rendered_lines`.
        def cursor_marker
          "|"
        end
      end
    end
  end
end
