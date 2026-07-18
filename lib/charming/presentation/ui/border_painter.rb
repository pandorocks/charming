# frozen_string_literal: true

module Charming
  module UI
    # BorderPainter draws a Border's glyphs around content lines, optionally
    # coloring the border. *foreground* is a single color or a per-side hash
    # (`{top:, right:, bottom:, left:}`); corners take the top/bottom row's
    # color. *background* colors border cells; when it merely inherits the box
    # background (background_explicit: false) it only paints alongside a
    # foreground, preserving unstyled borders on unstyled boxes.
    class BorderPainter
      DEFAULT_SIDES = %i[top right bottom left].freeze

      def initialize(border:, sides: nil, foreground: nil, background: nil, background_explicit: false)
        @border = border
        @sides = Array(sides || DEFAULT_SIDES).map(&:to_sym)
        @foreground = foreground
        @background = background
        @background_explicit = background_explicit
      end

      def paint(lines, inner_width)
        horizontal = @border.horizontal * inner_width
        body = lines.map { |line| border_line(line, inner_width) }

        [top_border(horizontal), *body, bottom_border(horizontal)].compact
      end

      private

      def border_line(line, width)
        left = @sides.include?(:left) ? render_border(@border.vertical, :left) : ""
        right = @sides.include?(:right) ? render_border(@border.vertical, :right) : ""

        "#{left}#{Width.pad_to(line, width)}#{right}"
      end

      def top_border(horizontal)
        return unless @sides.include?(:top)
        return render_border(horizontal, :top) unless full_horizontal?

        render_border("#{@border.top_left}#{horizontal}#{@border.top_right}", :top)
      end

      def bottom_border(horizontal)
        return unless @sides.include?(:bottom)
        return render_border(horizontal, :bottom) unless full_horizontal?

        render_border("#{@border.bottom_left}#{horizontal}#{@border.bottom_right}", :bottom)
      end

      def full_horizontal?
        @sides.include?(:left) && @sides.include?(:right)
      end

      def render_border(value, side)
        foreground = side_foreground(side)
        return value unless foreground || @background_explicit

        Style.new(foreground: foreground, background: @background).render(value)
      end

      def side_foreground(side)
        @foreground.is_a?(Hash) ? @foreground[side] : @foreground
      end
    end
  end
end
