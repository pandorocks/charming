# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      # TextInput is a single-line text editor component. Supports printable character insertion,
      # cursor movement (left/right/home/end), and deletion (backspace/delete). The component
      # exposes its `value` and `cursor` positions as reader methods; when an explicit `width:`
      # is given, the rendered output is padded to that width via a UI::Style.
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

        # The current input string and the byte offset of the cursor within it.
        attr_reader :value, :cursor

        # *value* is the initial text. *placeholder* is shown when the value is empty.
        # *width* optionally constrains the rendered output width; *cursor* defaults to the end.
        def initialize(value: "", placeholder: "", width: nil, cursor: nil)
          super()
          @value = value.dup
          @placeholder = placeholder
          @width = width
          @cursor = cursor || @value.length
          clamp_position
        end

        # Handles key events. Inserts printable characters, otherwise dispatches via KEY_ACTIONS.
        # Returns :handled when the event was consumed, nil otherwise.
        def handle_key(event)
          return :handled if character_event?(event) && insert(event.char)

          super
        end

        # Renders the value with a cursor marker. When *width* was given at construction, the
        # output is padded to that width via the configured style.
        def render
          rendered = render_value
          @width ? style.width(@width).render(rendered) : rendered
        end

        private

        attr_reader :placeholder

        # True when *event* carries a single printable character that should be inserted.
        def character_event?(event)
          event.respond_to?(:char) && event.char && event.char.length == 1 && printable?(event.char)
        end

        # True when *char* is not a control character (and therefore safe to insert).
        def printable?(char)
          !char.match?(/[[:cntrl:]]/)
        end

        # Inserts *char* at the cursor and advances the cursor by its byte length.
        def insert(char)
          @value = value[0...cursor] + char + value[cursor..]
          @cursor += char.length
        end

        # Moves the cursor one position left, when possible.
        def move_left
          @cursor -= 1 if cursor.positive?
        end

        # Moves the cursor one position right, when possible.
        def move_right
          @cursor += 1 if cursor < value.length
        end

        # Moves the cursor to the start of the value.
        def move_home
          @cursor = 0
        end

        # Moves the cursor to the end of the value.
        def move_end
          @cursor = value.length
        end

        # Deletes the character before the cursor (backspace behavior).
        def delete_before_cursor
          return if cursor.zero?

          @value = value[0...(cursor - 1)] + value[cursor..]
          @cursor -= 1
        end

        # Deletes the character at the cursor (delete-key behavior).
        def delete_at_cursor
          return if cursor >= value.length

          @value = value[0...cursor] + value[(cursor + 1)..]
        end

        # Renders the value with a "|" cursor marker at the current position. When the value is
        # empty, the placeholder is rendered instead, preceded by the cursor marker.
        def render_value
          return cursor_marker + placeholder if value.empty?

          value[0...cursor] + cursor_marker + value[cursor..]
        end

        # The literal character used to mark the cursor position in `render`.
        def cursor_marker
          "|"
        end

        # Clamps the cursor to the valid range `[0, value.length]`.
        def clamp_position
          @cursor = cursor.clamp(0, value.length)
        end
      end
    end
  end
end
