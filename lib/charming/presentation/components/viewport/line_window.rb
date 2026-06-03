# frozen_string_literal: true

require "unicode/display_width"

module Charming
  module Components
    class Viewport
      # LineWindow renders one content line inside the viewport's horizontal window.
      class LineWindow
        ANSI_PATTERN = /\e\[[0-9;]*m/

        def initialize(width:, column:, wrap:)
          @width = width
          @column = column
          @wrap = wrap
        end

        def render(line)
          return line unless width
          return pad_line(line, width) if wrap

          pad_line(clip_line(line), width)
        end

        private

        attr_reader :width, :column, :wrap

        def clip_line(line)
          clipped = clip_tokens(line.to_s)
          needs_reset?(clipped) ? "#{clipped}\e[0m" : clipped
        end

        def clip_tokens(line)
          state = {cursor: 0, output: +""}
          line.scan(/#{ANSI_PATTERN}|./mo) do |token|
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

        def ansi?(token)
          token.match?(ANSI_PATTERN)
        end
      end
    end
  end
end
