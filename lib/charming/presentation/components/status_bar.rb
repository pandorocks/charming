# frozen_string_literal: true

module Charming
  module Components
    # StatusBar renders a single fixed-width row with left/center/right segments —
    # the classic TUI bottom bar for mode indicators, hints, and app state.
    #
    #   StatusBar.new(width: screen.width, left: "NORMAL", right: "main ⎇")
    #
    # When *hints* is given (an array of [key, description] pairs), the center segment
    # renders them as `key description` pairs — pass a controller's key bindings to get
    # an automatic hint line.
    class StatusBar < Component
      # *width* is the total bar width. *left*/*center*/*right* are the segment contents.
      # *hints* renders key-hint pairs in the center when no explicit center is given.
      # *style* overrides the default bar background style.
      def initialize(width:, left: "", center: "", right: "", hints: nil, style: nil, theme: nil)
        super(theme: theme)
        @width = width
        @left = left.to_s
        @center = center.to_s
        @right = right.to_s
        @hints = hints
        @bar_style = style
      end

      # Renders the bar: left-aligned, centered, and right-aligned segments on one row,
      # padded to the full width and wrapped in the bar style.
      def render
        resolved_style.render(compose_segments)
      end

      private

      attr_reader :width, :left, :right

      # The center content: the explicit center, or formatted hints when given.
      def center
        return @center unless @center.empty?
        return "" unless @hints

        @hints.map { |key, description| "#{key} #{description}" }.join("  ")
      end

      # Lays the three segments onto a single row of exactly *width* columns.
      # Center is positioned at the true middle; left/right anchor the edges.
      # Segments are clipped if they would collide.
      def compose_segments
        row = " " * width
        row = place_segment(row, left, 0)
        center_text = center
        center_start = [(width - UI::Width.measure(center_text)) / 2, 0].max
        row = place_segment(row, center_text, center_start)
        right_start = [width - UI::Width.measure(right), 0].max
        place_segment(row, right, right_start)
      end

      # Writes *text* into *row* starting at *column*, clipping to the row width.
      def place_segment(row, text, column)
        return row if text.empty?

        visible = UI.visible_slice(text, 0, width - column)
        prefix = UI.visible_slice(row, 0, column)
        suffix_start = column + UI::Width.measure(visible)
        suffix = UI.visible_slice(row, suffix_start, width - suffix_start)
        "#{prefix}#{visible}#{suffix}"
      end

      # The user style or a muted reverse bar derived from the theme.
      def resolved_style
        @bar_style || theme.selected
      end
    end
  end
end
