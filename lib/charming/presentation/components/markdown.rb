# frozen_string_literal: true

module Charming
  module Components
    # Markdown renders Markdown source as ANSI-styled terminal text. Parsing is delegated to
    # `Charming::Markdown::Renderer`; set *syntax_highlighting* to false to disable
    # Rouge-backed code block highlighting.
    class Markdown < Component
      # *content* is the Markdown source string. *width* optionally sets the wrap width.
      # *syntax_highlighting* enables Rouge for code blocks (defaults to true).
      def initialize(content:, width: nil, theme: nil, syntax_highlighting: true)
        super(theme: theme)
        @content = content
        @width = width
        @syntax_highlighting = syntax_highlighting
      end

      # Renders the Markdown body to a styled, terminal-safe string.
      def render
        Charming::Markdown::Renderer.new(
          content: @content,
          width: @width,
          theme: theme,
          syntax_highlighting: @syntax_highlighting
        ).render
      end
    end
  end
end
