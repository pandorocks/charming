# frozen_string_literal: true

module Charming
  module Components
    # Breadcrumbs renders a navigation trail like `Home › Projects › My App`, with the
    # final (current) item highlighted and ancestors muted.
    class Breadcrumbs < Component
      DEFAULT_SEPARATOR = " › "

      # *items* is the trail (strings or anything responding to to_s), first-to-last.
      # *separator* joins the items.
      def initialize(items:, separator: DEFAULT_SEPARATOR, theme: nil)
        super(theme: theme)
        @items = Array(items).map(&:to_s)
        @separator = separator
      end

      # Renders the trail; ancestors muted, current item in the title style.
      def render
        return "" if @items.empty?

        *ancestors, current = @items
        parts = ancestors.map { |item| theme.muted.render(item) }
        parts << theme.title.render(current)
        parts.join(theme.muted.render(@separator))
      end
    end
  end
end
