# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Markdown < Component
        def initialize(content:, width: nil, theme: nil, syntax_highlighting: true)
          super(theme: theme)
          @content = content
          @width = width
          @syntax_highlighting = syntax_highlighting
        end

        def render
          Charming::Presentation::Markdown::Renderer.new(
            content: @content,
            width: @width,
            theme: theme,
            syntax_highlighting: @syntax_highlighting
          ).render
        end
      end
    end
  end
end
