# frozen_string_literal: true

require_relative "../component"

module Charming
  module Components
    class TextInput < Component
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
        clamp_cursor
      end

      def handle_key(event)
        key = event.respond_to?(:key) ? event.key : event
        if character_event?(event)
          insert(event.char)
          return :handled
        end

        handle_named_key(key)
      end

      def render
        rendered = render_value
        @width ? style.width(@width).render(rendered) : rendered
      end

      private

      attr_reader :placeholder

      def handle_named_key(key)
        action = KEY_ACTIONS[key.to_sym]
        return unless action

        send(action)
        :handled
      end

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

      def clamp_cursor
        @cursor = cursor.clamp(0, value.length)
      end
    end
  end
end
