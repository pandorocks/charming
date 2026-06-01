# frozen_string_literal: true

module Charming
  module Presentation
    module UI
      class BorderPainter
        DEFAULT_SIDES = %i[top right bottom left].freeze

        def initialize(border:, sides: nil, foreground: nil, background: nil)
          @border = border
          @sides = Array(sides || DEFAULT_SIDES).map(&:to_sym)
          @foreground = foreground
          @background = background
        end

        def paint(lines, inner_width)
          horizontal = @border.horizontal * inner_width
          body = lines.map { |line| border_line(line, inner_width) }

          [top_border(horizontal), *body, bottom_border(horizontal)].compact
        end

        private

        def border_line(line, width)
          left = @sides.include?(:left) ? render_border(@border.vertical) : ""
          right = @sides.include?(:right) ? render_border(@border.vertical) : ""

          "#{left}#{line}#{" " * (width - Width.measure(line))}#{right}"
        end

        def top_border(horizontal)
          return unless @sides.include?(:top)
          return render_border(horizontal) unless full_horizontal?

          render_border("#{@border.top_left}#{horizontal}#{@border.top_right}")
        end

        def bottom_border(horizontal)
          return unless @sides.include?(:bottom)
          return render_border(horizontal) unless full_horizontal?

          render_border("#{@border.bottom_left}#{horizontal}#{@border.bottom_right}")
        end

        def full_horizontal?
          @sides.include?(:left) && @sides.include?(:right)
        end

        def render_border(value)
          return value unless @foreground

          Style.new(foreground: @foreground, background: @background).render(value)
        end
      end
    end
  end
end
