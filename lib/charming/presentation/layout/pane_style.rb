# frozen_string_literal: true

module Charming
  module Layout
    # PaneStyle holds a Pane's base style and the focused-state override.
    # It resolves which style to use at render time given the pane's current
    # focus state and the view's theme.
    class PaneStyle
      attr_reader :style, :focused_style

      def self.build(style: nil, focused_style: nil)
        new(style: style, focused_style: focused_style)
      end

      def initialize(style:, focused_style:)
        @style, @focused_style = style, focused_style
        freeze
      end

      def ==(other)
        other.is_a?(PaneStyle) &&
          style == other.style && focused_style == other.focused_style
      end
      alias_method :eql?, :==

      def hash
        [style, focused_style].hash
      end

      # Returns the active style for *focused*: the focused override when the
      # pane is focused, otherwise the configured *style* or a default UI::Style.
      def resolve(view, focused:)
        return focused_style || view.__send__(:theme).title if focused

        style || UI.style
      end
    end
  end
end
