# frozen_string_literal: true

require "kramdown"

module Charming
  module Presentation
    module Markdown
      class Renderer
        DEFAULT_RULE_WIDTH = 40

        attr_reader :content, :width, :theme, :syntax_highlighting

        def initialize(content:, width: nil, theme: UI::Theme.default, syntax_highlighting: true)
          @content = content
          @width = width
          @theme = theme || UI::Theme.default
          @syntax_highlighting = syntax_highlighting
        end

        def render
          document = Kramdown::Document.new(content.to_s)
          render_blocks(document.root.children)
        end

        def render_blocks(elements, list_depth: 0, width: @width)
          context = RenderContext.from(width: width, list_depth: list_depth)
          elements.filter_map do |element|
            rendered = block_renderer.render(element, context: context)
            rendered unless rendered.to_s.empty?
          end.join("\n\n")
        end

        def render_inlines(elements, width: @width)
          context = RenderContext.from(width: width)
          elements.map { |element| inline_renderer.render(element, context: context) }.join
        end

        def wrap(value, width:)
          return value unless width

          value.to_s.lines(chomp: true).map { |line| wrap_line(line, width) }.join("\n")
        end

        def style_for(name, fallback:)
          return theme.public_send(name) if theme.respond_to?(name)

          fallback
        end

        def theme_style(name)
          return theme.public_send(name) if theme.respond_to?(name)

          UI::Theme::DEFAULT_TOKENS.fetch(name).then { |token| UI::Theme.new(name => token).public_send(name) }
        end

        private

        def block_renderer
          @block_renderer ||= BlockRenderer.new(renderer: self)
        end

        def inline_renderer
          @inline_renderer ||= InlineRenderer.new(renderer: self)
        end

        def wrap_line(line, width)
          return line if UI::Width.measure(line) <= width

          lines = []
          current = +""

          line.split(/\s+/).each do |word|
            candidate = current.empty? ? word : "#{current} #{word}"

            if !current.empty? && UI::Width.measure(candidate) > width
              lines << current.rstrip
              current = word
            else
              current = candidate
            end
          end

          lines << current.rstrip unless current.empty?
          lines.join("\n")
        end
      end
    end
  end
end
