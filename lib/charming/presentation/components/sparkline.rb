# frozen_string_literal: true

module Charming
  module Components
    # Sparkline renders a series of numbers as a compact one-line bar graph using the eighth-block
    # glyphs `▁▂▃▄▅▆▇█` — one cell per value, scaled between the series' min and max. Pure text, so it
    # works on every terminal. Pass an optional `style:` ({Charming::UI::Style}) to colour it.
    class Sparkline < Component
      # The eight bar heights, shortest to tallest.
      BARS = %w[▁ ▂ ▃ ▄ ▅ ▆ ▇ █].freeze

      # *values* is the numeric series. *style* optionally paints the result. *theme* is forwarded.
      def initialize(values:, style: nil, theme: nil)
        super(theme: theme)
        @values = values
        @style = style
      end

      # Renders one bar glyph per value (empty string for an empty series).
      def render
        return "" if @values.empty?

        glyphs = @values.map { |value| BARS[level(value)] }.join
        @style ? @style.render(glyphs) : glyphs
      end

      private

      # The 0..7 bar index for *value*, scaled across the series range (flat series → lowest bar).
      def level(value)
        min, max = @values.minmax
        return 0 if max == min

        ((value - min).to_f / (max - min) * (BARS.length - 1)).round
      end
    end
  end
end
