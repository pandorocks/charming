# frozen_string_literal: true

module Charming
  module Components
    # Chart plots a numeric *series* into a `width`×`height` box of character cells. `kind: :line`
    # (default) draws a connected line on a {Charming::UI::BrailleCanvas} (subpixel resolution);
    # `kind: :bar` draws vertical eighth-block bars. Pure text — works on every terminal — and
    # composes with `row`/`column`/`box`. Pass an optional `style:` ({Charming::UI::Style}) to colour it.
    class Chart < Component
      # Vertical fill levels for bar mode, empty (0) to full (8 eighths).
      VBARS = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"].freeze

      # *series* is the numeric data. *width*/*height* size the chart in character cells. *kind* is
      # `:line` or `:bar`. *style* optionally paints the result. *theme* is forwarded.
      def initialize(series:, width:, height:, kind: :line, style: nil, theme: nil)
        super(theme: theme)
        @series = series
        @width = width
        @height = height
        @kind = kind
        @style = style
      end

      # Renders the chart (empty string for an empty series or a non-positive box).
      def render
        return "" if @series.empty? || @width < 1 || @height < 1

        body = (@kind == :bar) ? bars : line_plot
        @style ? @style.render(body) : body
      end

      private

      # A connected line on a braille canvas sized to the cell box.
      def line_plot
        canvas = UI::BrailleCanvas.new(@width * 2, @height * 4)
        points = scaled_points(@width * 2, @height * 4)
        points.each { |x, y| canvas.set(x, y) }
        points.each_cons(2) { |(x0, y0), (x1, y1)| canvas.line(x0, y0, x1, y1) }
        canvas.to_s
      end

      # Maps the series to canvas pixels: x spread across the width, y inverted (0 at top) and scaled
      # between the series' min and max.
      def scaled_points(pixel_width, pixel_height)
        min, max = @series.minmax
        span = (max - min).to_f
        span = 1.0 if span.zero?
        last = @series.length - 1
        @series.each_with_index.map do |value, index|
          x = last.zero? ? 0 : (index * (pixel_width - 1) / last.to_f).round
          y = ((1 - (value - min) / span) * (pixel_height - 1)).round
          [x, y]
        end
      end

      # Vertical eighth-block bars, one column per cell, sampled from the series and scaled from a
      # baseline of min(0, series-min).
      def bars
        columns = sample(@series, @width)
        base = [columns.min, 0].min
        span = (columns.max - base).to_f
        span = 1.0 if span.zero?
        eighths = columns.map { |value| ((value - base) / span * @height * 8).round }
        Array.new(@height) do |row|
          from_bottom = @height - 1 - row
          eighths.map { |total| VBARS[(total - from_bottom * 8).clamp(0, 8)] }.join
        end.join("\n")
      end

      # Resamples *series* to exactly *count* values via nearest-neighbour (identity when sizes match).
      def sample(series, count)
        size = series.length
        return series if size == count

        Array.new(count) { |index| series[(index * size / count.to_f).floor.clamp(0, size - 1)] }
      end
    end
  end
end
