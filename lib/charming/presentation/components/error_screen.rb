# frozen_string_literal: true

module Charming
  module Components
    # ErrorScreen renders an unhandled exception as a styled, centered panel instead of
    # letting the backtrace crash into the raw terminal. Shows the exception class, message,
    # the most relevant backtrace lines, and a dismiss hint. The Runtime displays it when a
    # dispatched action raises and no `rescue_from` handler claimed the exception.
    class ErrorScreen < Component
      DEFAULT_WIDTH = 64
      BACKTRACE_LINES = 6

      # *error* is the rescued exception. *width* is the panel's total width. *root* is the
      # app root used to shorten backtrace paths (defaults to the working directory).
      def initialize(error:, width: DEFAULT_WIDTH, root: Dir.pwd, theme: nil)
        super(theme: theme)
        @error = error
        @width = width
        @root = root
      end

      # Renders the bordered error panel.
      def render
        box(column(*sections, gap: 1), style: panel_style)
      end

      private

      attr_reader :error, :width, :root

      # The panel sections: class name, message, backtrace, dismiss hint.
      def sections
        [
          text(error.class.name, style: theme.warn.bold),
          text(wrapped_message),
          backtrace_section,
          text("press any key to continue · q to quit", style: theme.muted)
        ].compact
      end

      # The exception message, wrapped to the panel's inner width.
      def wrapped_message
        Charming::Markdown::TextWrapper.new(width: inner_width).wrap(error.message.to_s)
      end

      # The first few backtrace lines with the app root stripped, styled muted.
      def backtrace_section
        lines = (error.backtrace || []).first(BACKTRACE_LINES)
        return nil if lines.empty?

        body = lines.map { |line| shorten(line) }.join("\n")
        text(body, style: theme.muted)
      end

      # Strips the app root prefix and clips each backtrace line to the inner width.
      def shorten(line)
        cleaned = line.delete_prefix("#{root}/")
        UI.visible_slice(cleaned, 0, inner_width)
      end

      # The panel's content width inside border and padding.
      def inner_width
        [width - 6, 10].max
      end

      # The bordered panel style: warn-colored rounded border with padding.
      def panel_style
        style.border(:rounded, foreground: :red).padding(1, 2).width(width)
      end
    end
  end
end
