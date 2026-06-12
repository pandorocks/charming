# frozen_string_literal: true

module Journal
  module Entries
    class ShowView < Charming::View
      def render
        column(heading, body, gap: 1)
      end

      private

      def heading
        favorites = entries_list.items.count(&:favorite?)
        row(
          text("Journal", style: theme.title),
          text("#{entries_list.items.length} entries · #{favorites} ★", style: theme.muted),
          gap: 2
        )
      end

      def body
        return empty_state if entries_list.items.empty?

        render_component(entries_list)
      end

      def empty_state
        render_component(
          Charming::Components::EmptyState.new(
            message: "No entries yet — press n to write your first.",
            theme: theme
          )
        )
      end
    end
  end
end
