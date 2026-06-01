# frozen_string_literal: true

module Charming
  module Presentation
    module Markdown
      class InlineRenderer
        def initialize(renderer:)
          @renderer = renderer
          build_handlers
        end

        def render(element, context:)
          handler = @handlers[element.type] || method(:render_unknown)
          handler.call(element, context)
        end

        private

        attr_reader :handlers

        def build_handlers
          r = @renderer
          @handlers = {
            text: ->(element, _context) { element.value.to_s },
            strong: ->(element, context) { render_styled(element, context, :markdown_strong) { |s| s.bold } },
            em: ->(element, context) { render_styled(element, context, :markdown_emphasis) { |s| s.italic } },
            codespan: ->(element, _context) { r.style_for(:markdown_inline_code, fallback: r.theme_style(:warn)).render(element.value.to_s) },
            a: ->(element, context) { send(:render_link, element, context) },
            br: ->(_element, _context) { "\n" },
            entity: ->(element, _context) { element.value.respond_to?(:char) ? element.value.char : element.value.to_s }
          }.freeze
        end

        def render_styled(element, context, style_name)
          rendered = @renderer.render_inlines(element.children, width: context.width)
          style = @renderer.style_for(style_name, fallback: yield(@renderer.theme_style(:text)))
          style.render(rendered)
        end

        def render_link(element, context)
          label = @renderer.render_inlines(element.children, width: context.width)
          href = element.attr["href"].to_s
          rendered = href.empty? ? label : "#{label} <#{href}>"
          @renderer.style_for(:markdown_link, fallback: @renderer.theme_style(:info).underline).render(rendered)
        end

        def render_unknown(element, context)
          element.children.empty? ? element.value.to_s : @renderer.render_inlines(element.children, width: context.width)
        end
      end
    end
  end
end
