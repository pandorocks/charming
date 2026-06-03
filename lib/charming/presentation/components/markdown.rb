# frozen_string_literal: true

module Charming
  module Components
    # Markdown renders CommonMark/GFM source as ANSI-styled terminal text.
    class Markdown < Component
      def initialize(content:, width: nil, theme: nil, syntax_highlighting: true, style: :dark, base_url: nil)
        super(theme: theme)
        @content = content
        @width = width
        @syntax_highlighting = syntax_highlighting
        @style = style
        @base_url = base_url
      end

      # Renders the Markdown body to a styled, terminal-safe string.
      def render
        Charming::Markdown::Renderer.new(
          content: @content,
          width: @width,
          theme: theme,
          syntax_highlighting: @syntax_highlighting,
          style: @style,
          base_url: @base_url
        ).render
      end
    end
  end
end
