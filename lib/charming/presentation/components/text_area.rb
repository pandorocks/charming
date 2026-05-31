# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class TextArea < Component
        attr_reader :value, :cursor, :offset, :preferred_column

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

        def render
          visible_lines.map { |line| render_line(line) }.join("\n")
        end

        private

        attr_reader :placeholder, :width, :height

        def newline_event?(event)
          key = Charming.key_of(event)
          return true if key == :enter && event.respond_to?(:shift) && event.shift
          return true if key == :j && event.respond_to?(:ctrl) && event.ctrl

          false
        end

        def character_event?(event)
          event.respond_to?(:char) && event.char && event.char.length == 1 && printable?(event.char)
        end

        def printable?(char)
          !char.match?(/[[:cntrl:]]/)
        end

        def insert(text)
          @value = value[0...cursor].to_s + text + value[cursor..].to_s
          @cursor += text.length
          reset_preferred_column
          ensure_cursor_visible
        end

        def move_left
          @cursor -= 1 if cursor.positive?
          reset_preferred_column
          ensure_cursor_visible
        end

        def move_right
          @cursor += 1 if cursor < value.length
          reset_preferred_column
          ensure_cursor_visible
        end

        def move_up
          move_vertical(-1)
        end

        def move_down
          move_vertical(+1)
        end

        def move_home
          row, = cursor_position
          @cursor = line_start(row)
          reset_preferred_column
          ensure_cursor_visible
        end

        def move_end
          row, = cursor_position
          @cursor = line_start(row) + line_length(row)
          reset_preferred_column
          ensure_cursor_visible
        end

        def delete_before_cursor
          return if cursor.zero?

          @value = value[0...(cursor - 1)].to_s + value[cursor..].to_s
          @cursor -= 1
          reset_preferred_column
          ensure_cursor_visible
        end

        def delete_at_cursor
          return if cursor >= value.length

          @value = value[0...cursor].to_s + value[(cursor + 1)..].to_s
          reset_preferred_column
          ensure_cursor_visible
        end

        def page_up
          @offset -= viewport_height
          clamp_offset
        end

        def page_down
          @offset += viewport_height
          clamp_offset
        end

        def move_vertical(delta)
          row, column = cursor_position
          target_row = (row + delta).clamp(0, lines.length - 1)
          @preferred_column ||= column
          @cursor = line_start(target_row) + [@preferred_column, line_length(target_row)].min
          ensure_cursor_visible
        end

        def reset_preferred_column
          @preferred_column = cursor_position.last
        end

        def cursor_position
          before = value[0...cursor].to_s
          row = before.count("\n")
          last_newline = before.rindex("\n")
          column = last_newline ? before.length - last_newline - 1 : before.length
          [row, column]
        end

        def line_start(row)
          lines.first(row).sum(&:length) + row
        end

        def line_length(row)
          lines.fetch(row, "").length
        end

        def lines
          value.empty? ? [""] : value.split("\n", -1)
        end

        def rendered_lines
          return [cursor_marker + placeholder] if value.empty?

          (value[0...cursor].to_s + cursor_marker + value[cursor..].to_s).split("\n", -1)
        end

        def visible_lines
          ensure_cursor_visible
          rendered = rendered_lines.slice(offset, viewport_height) || []
          return rendered unless height

          rendered + Array.new([height - rendered.length, 0].max, "")
        end

        def render_line(line)
          return line unless width

          clipped = UI.visible_slice(line, 0, width)
          clipped + (" " * [width - UI::Width.measure(clipped), 0].max)
        end

        def ensure_cursor_visible
          row, = cursor_position
          @offset = row if row < offset
          @offset = row - viewport_height + 1 if row >= offset + viewport_height
          clamp_offset
        end

        def clamp_position
          @cursor = cursor.clamp(0, value.length)
          clamp_offset
        end

        def clamp_offset
          @offset = offset.clamp(0, max_offset)
        end

        def max_offset
          [lines.length - viewport_height, 0].max
        end

        def viewport_height
          height || lines.length
        end

        def cursor_marker
          "|"
        end
      end
    end
  end
end
