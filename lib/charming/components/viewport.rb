# frozen_string_literal: true

require "unicode/display_width"

require_relative "../component"

module Charming
  module Components
    class Viewport < Component
      ANSI_PATTERN = /\e\[[0-9;]*m/
      KEY_ACTIONS = {
        up: :scroll_up,
        down: :scroll_down,
        page_up: :page_up,
        page_down: :page_down,
        home: :scroll_home,
        end: :scroll_end,
        left: :scroll_left,
        right: :scroll_right
      }.freeze

      attr_reader :offset, :column

      def initialize(content:, width: nil, height: nil, offset: 0, column: 0)
        super()
        @content = content
        @width = width
        @height = height
        @offset = offset
        @column = column
        clamp_position
      end

      def render
        visible_lines.map { |line| render_line(line) }.join("\n")
      end

      def handle_key(event)
        key = event.respond_to?(:key) ? event.key : event
        action = KEY_ACTIONS[key.to_sym]
        return unless action

        send(action)
        :handled
      end

      private

      attr_reader :content, :width, :height

      def scroll_up
        @offset -= 1
        clamp_position
      end

      def scroll_down
        @offset += 1
        clamp_position
      end

      def page_up
        @offset -= page_size
        clamp_position
      end

      def page_down
        @offset += page_size
        clamp_position
      end

      def scroll_home
        @offset = 0
        @column = 0
      end

      def scroll_end
        @offset = max_offset
        @column = max_column
      end

      def scroll_left
        @column -= 1
        clamp_position
      end

      def scroll_right
        @column += 1
        clamp_position
      end

      def clamp_position
        @offset = offset.clamp(0, max_offset)
        @column = column.clamp(0, max_column)
      end

      def visible_lines
        lines = content_lines.slice(offset, viewport_height) || []
        return lines unless height

        lines + Array.new([height - lines.length, 0].max, "")
      end

      def render_line(line)
        return line unless width

        pad_line(clip_line(line), width)
      end

      def clip_line(line)
        clipped = clip_tokens(line.to_s)
        needs_reset?(clipped) ? "#{clipped}\e[0m" : clipped
      end

      def clip_tokens(line)
        state = { cursor: 0, output: +"" }
        line.scan(/#{ANSI_PATTERN}|./m) do |token|
          ansi?(token) ? append_ansi(state, token) : append_character(state, token)
        end
        state.fetch(:output)
      end

      def append_ansi(state, token)
        state.fetch(:output) << token
      end

      def append_character(state, char)
        char_width = Unicode::DisplayWidth.of(char)
        cursor = state.fetch(:cursor)
        state.fetch(:output) << char if visible?(cursor, char_width)
        state[:cursor] = cursor + char_width
      end

      def visible?(cursor, char_width)
        cursor >= column && cursor + char_width <= column + width
      end

      def needs_reset?(value)
        value.match?(ANSI_PATTERN) && !value.end_with?("\e[0m")
      end

      def pad_line(line, target_width)
        line + (" " * [target_width - UI::Width.measure(line), 0].max)
      end

      def content_lines
        rendered_content.lines(chomp: true)
      end

      def rendered_content
        content.respond_to?(:render) ? content.render.to_s : content.to_s
      end

      def viewport_height
        height || content_lines.length
      end

      def page_size
        [viewport_height, 1].max
      end

      def max_offset
        [content_lines.length - viewport_height, 0].max
      end

      def max_column
        return 0 unless width

        [content_width - width, 0].max
      end

      def content_width
        content_lines.map { |line| UI::Width.measure(line) }.max || 0
      end

      def ansi?(token)
        token.match?(ANSI_PATTERN)
      end
    end
  end
end
