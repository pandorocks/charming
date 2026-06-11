# frozen_string_literal: true

module Charming
  module Layout
    # PaneGeometry holds a Pane's sizing (width, height, grow, min/max constraints)
    # and inset configuration (border + padding). It knows how to inset a Rect for the
    # content area and how to expand CSS-style 1/2/4-value padding.
    class PaneGeometry
      attr_reader :width, :height, :grow, :border, :padding,
        :min_width, :max_width, :min_height, :max_height

      def self.build(width: nil, height: nil, grow: nil, border: nil, padding: nil,
        min_width: nil, max_width: nil, min_height: nil, max_height: nil)
        new(width: width, height: height, grow: grow,
          border: (border == true) ? :normal : border, padding: padding,
          min_width: min_width, max_width: max_width,
          min_height: min_height, max_height: max_height)
      end

      def initialize(width:, height:, grow:, border:, padding:,
        min_width: nil, max_width: nil, min_height: nil, max_height: nil)
        @width, @height, @grow, @border, @padding = width, height, grow, border, padding
        @min_width, @max_width, @min_height, @max_height = min_width, max_width, min_height, max_height
        @padding_values = padding ? expand_padding(Array(padding)) : [0, 0, 0, 0]
        freeze
      end

      def ==(other)
        other.is_a?(PaneGeometry) &&
          width == other.width && height == other.height && grow == other.grow &&
          border == other.border && padding == other.padding &&
          min_width == other.min_width && max_width == other.max_width &&
          min_height == other.min_height && max_height == other.max_height
      end
      alias_method :eql?, :==

      def hash
        [width, height, grow, border, padding, min_width, max_width, min_height, max_height].hash
      end

      def border_top = border ? 1 : 0
      def border_right = border ? 1 : 0
      def border_bottom = border ? 1 : 0
      def border_left = border ? 1 : 0

      attr_reader :padding_values

      def padding_top = padding ? @padding_values[0] : 0
      def padding_right = padding ? @padding_values[1] : 0
      def padding_bottom = padding ? @padding_values[2] : 0
      def padding_left = padding ? @padding_values[3] : 0

      def inset(rect)
        rect.inset(
          top: border_top + padding_top,
          right: border_right + padding_right,
          bottom: border_bottom + padding_bottom,
          left: border_left + padding_left
        )
      end

      def border_style
        (border == true) ? :normal : border
      end

      private

      def expand_padding(values)
        case values.length
        when 1 then [values[0], values[0], values[0], values[0]]
        when 2 then [values[0], values[1], values[0], values[1]]
        when 4 then values
        else
          raise ArgumentError, "padding expects 1, 2, or 4 values"
        end
      end
    end
  end
end
