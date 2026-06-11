# frozen_string_literal: true

module Charming
  module Components
    # Toast is a small auto-dismissing notification panel, usually composited as an
    # overlay anchored to a screen corner. Controllers manage its lifetime with the
    # `show_toast` / `dismiss_toast` helpers (which pair it with a timer); the component
    # itself just renders the styled box.
    #
    #   Toast.new(message: "Saved!", kind: :success)
    #
    # *kind* picks the accent style: :info (default), :success, :warn, or :error.
    class Toast < Component
      KINDS = %i[info success warn error].freeze

      attr_reader :message, :kind

      # *message* is the toast text. *kind* is the visual accent. *width* optionally
      # fixes the box width (otherwise it hugs the message).
      def initialize(message:, kind: :info, width: nil, theme: nil)
        super(theme: theme)
        @message = message.to_s
        @kind = KINDS.include?(kind) ? kind : :info
        @width = width
      end

      # Renders the bordered toast box with a kind-colored border.
      def render
        box(message, style: toast_style)
      end

      private

      # A rounded-border box accented by the kind's theme style.
      def toast_style
        base = style.border(:rounded, foreground: accent_color).padding(0, 1)
        @width ? base.width(@width) : base
      end

      # Maps the kind to a border color: info/cyan-ish, success/green, warn/yellow, error/red.
      def accent_color
        case kind
        when :success then :green
        when :warn then :yellow
        when :error then :red
        else :cyan
        end
      end
    end
  end
end
