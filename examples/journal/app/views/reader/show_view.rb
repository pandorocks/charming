# frozen_string_literal: true

module Journal
  module Reader
    class ShowView < Charming::View
      def render
        column(header, render_component(body_pane), gap: 1)
      end

      private

      def header
        crumbs = Charming::Components::Breadcrumbs.new(
          items: ["Journal", entry.title],
          theme: theme
        )
        row(render_component(crumbs), badges, gap: 2)
      end

      def badges
        mood = Charming::Components::Badge.new("#{entry.mood_emoji} #{entry.mood}", theme: theme)
        parts = [render_component(mood), text(entry.created_at.strftime("%B %d, %Y"), style: theme.muted)]
        parts << text("★ favorite", style: theme.warn) if entry.favorite?
        row(*parts, gap: 2)
      end
    end
  end
end
