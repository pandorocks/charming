# frozen_string_literal: true

module Journal
  module Stats
    class ShowView < Charming::View
      def render
        column(heading, summary, mood_bars, export_section, gap: 1)
      end

      private

      def heading
        text "Writing stats", style: theme.title
      end

      def summary
        row(
          text("#{total} entries", style: theme.text),
          text("#{streak}-day streak", style: streak.positive? ? theme.info : theme.muted),
          gap: 3
        )
      end

      def mood_bars
        rows = mood_counts.map do |mood, count|
          bar = Charming::Components::Progressbar.new(total: [total, 1].max, label: "#{mood} (#{count})")
          bar.update(count)
          "#{Journal::Entry::MOOD_EMOJI.fetch(mood)}  #{render_component(bar)}"
        end
        column(*rows)
      end

      def export_section
        return text("press x to export the journal to Markdown", style: theme.muted) unless stats.exporting

        bar = Charming::Components::Progressbar.new(
          total: [stats.export_total, 1].max,
          label: "exporting #{stats.export_current}/#{stats.export_total}"
        )
        bar.update(stats.export_current)
        spinner = Charming::Components::ActivityIndicator.new(index: stats.activity_index, label: "writing")
        column(render_component(spinner), render_component(bar))
      end
    end
  end
end
