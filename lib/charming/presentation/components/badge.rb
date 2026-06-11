# frozen_string_literal: true

module Charming
  module Components
    # Badge is a small inline label rendered as a styled pill — useful for versions,
    # counts, and statuses inside status bars, lists, and headers.
    #
    #   Badge.new("v1.2").render            # themed default
    #   Badge.new("3 errors", style: theme.warn).render
    class Badge < Component
      # *label* is the badge text. *style* overrides the default themed style.
      def initialize(label, style: nil, theme: nil)
        super(theme: theme)
        @label = label.to_s
        @badge_style = style
      end

      # Renders the pill: a space-padded label with the badge style applied.
      def render
        resolved_style.render(" #{@label} ")
      end

      private

      # The user style or the theme's selected style (which guarantees contrast).
      def resolved_style
        @badge_style || theme.selected
      end
    end
  end
end
