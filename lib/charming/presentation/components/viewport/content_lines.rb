# frozen_string_literal: true

module Charming
  module Components
    class Viewport
      # ContentLines normalizes viewport content into display lines.
      class ContentLines
        def initialize(content:, width:, wrap:)
          @content = content
          @window_width = width
          @wrap = wrap
        end

        def lines
          return wrapped_lines if wrap?

          rendered_content.lines(chomp: true)
        end

        def display_width
          UI::Width.widest(lines)
        end

        private

        attr_reader :content, :window_width, :wrap

        def wrapped_lines
          rendered_content.lines(chomp: true).flat_map { |line| wrap_line(line) }
        end

        def wrap_line(line)
          line_width = UI::Width.measure(line)
          return [""] if line_width.zero?

          wrap_slices(line, line_width)
        end

        def wrap_slices(line, line_width)
          (0...line_width).step(window_width).map do |start_column|
            UI.visible_slice(line, start_column, window_width)
          end
        end

        def rendered_content
          content.respond_to?(:render) ? content.render.to_s : content.to_s
        end

        def wrap?
          wrap && window_width&.positive?
        end
      end
    end
  end
end
