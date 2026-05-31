# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class TextInput < Component
        include KeyboardHandler

        # Maps editing keys (left/right/home/end/backspace/delete) to the instance
        # methods they dispatch via KeyboardHandler. Each symbol key (e.g., :left)
        # maps to a method (e.g., :move_left) that adjusts cursor position or text content.
        KEY_ACTIONS = {
          left: :move_left,
          right: :move_right,
          home: :move_home,
          end: :move_end,
          backspace: :delete_before_cursor,
          delete: :delete_at_cursor
        }.freeze

        attr_reader :value, :cursor

        def initialize(value: "", placeholder: "", width: nil, cursor: nil)
          super()
          @value = value.dup
          @placeholder = placeholder
          @width = width
          @cursor = cursor || @value.length
          clamp_position
        end

        def handle_key(event)
          return :handled if character_event?(event) && insert(event.char)

          super
        end

        def render
          rendered = render_value
          @width ? style.width(@width).render(rendered) : rendered
        end

        private

        attr_reader :placeholder

        def character_event?(event)
          event.respond_to?(:char) && event.char && event.char.length == 1 && printable?(event.char)
        end

        def printable?(char)
          !char.match?(/[[:cntrl:]]/)
        end

        def insert(char)
          @value = value[0...cursor] + char + value[cursor..]
          @cursor += char.length
        end

        def move_left
          @cursor -= 1 if cursor.positive?
        end

        def move_right
          @cursor += 1 if cursor < value.length
        end

        def move_home
          @cursor = 0
        end

        def move_end
          @cursor = value.length
        end

        def delete_before_cursor
          return if cursor.zero?

          @value = value[0...(cursor - 1)] + value[cursor..]
          @cursor -= 1
        end

        def delete_at_cursor
          return if cursor >= value.length

          @value = value[0...cursor] + value[(cursor + 1)..]
        end

        def render_value
          return cursor_marker + placeholder if value.empty?

          value[0...cursor] + cursor_marker + value[cursor..]
        end

        def cursor_marker
          "|"
        end

        def clamp_position
          @cursor = cursor.clamp(0, value.length)
        end
      end
    end
  end
end
