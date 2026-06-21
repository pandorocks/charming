# frozen_string_literal: true

module DemoApp
  module Charts
    # Shows the data-viz components: a one-line sparkline, a braille line chart, and a block bar chart,
    # all driven from the same series. Pure text — works on every terminal.
    class ShowView < Charming::View
      def render
        column(
          section("Sparkline", sparkline),
          section("Line chart (braille)", line_chart),
          section("Bar chart (blocks)", bar_chart),
          gap: 1
        )
      end

      private

      def series
        assigns.fetch(:series)
      end

      def section(label, body)
        column(text(label, style: theme.title), body, gap: 0)
      end

      def sparkline
        render_component(Charming::Components::Sparkline.new(values: series, style: theme.info))
      end

      def line_chart
        render_component(Charming::Components::Chart.new(
          series: series, width: 32, height: 4, style: theme.info
        ))
      end

      def bar_chart
        render_component(Charming::Components::Chart.new(
          series: series, width: 16, height: 4, kind: :bar, style: theme.warn
        ))
      end
    end
  end
end
