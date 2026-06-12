# frozen_string_literal: true

module Journal
  module Compose
    class ShowView < Charming::View
      def render
        column(heading, render_component(form), gap: 1)
      end

      private

      def heading
        title = editing ? "Edit \"#{editing.title}\"" : "New entry"
        text title, style: theme.title
      end
    end
  end
end
