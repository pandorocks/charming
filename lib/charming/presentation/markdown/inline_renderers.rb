# frozen_string_literal: true

module Charming
  module Markdown
    # InlineRenderer dispatches Kramdown inline-level elements (text, strong, em,
    # codespan, link, line break, HTML entity) to their individual rendering handlers.
    # Handlers are built once at construction as a frozen hash of element-type symbols
    # to callables.
    class InlineRenderer
      # *renderer* is the parent Renderer (used to render nested inlines and look up styles).
      def initialize(renderer:)
        @renderer = renderer
        build_handlers
      end

      # Renders *element* using the handler registered for `element.type`. Unknown types
      # fall through to `render_unknown`.
      def render(element, context:)
        handler = @handlers[element.type] || method(:render_unknown)
        handler.call(element, context)
      end

      private

      # The frozen hash of element-type → handler mapping.
      attr_reader :handlers

      # Builds the handler hash for text, strong, em, codespan, link, br, and entity.
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

      # Renders a styled inline (strong/em) by first rendering children, then applying
      # the theme style and the block-form (e.g., `bold`/`italic`) decoration.
      def render_styled(element, context, style_name)
        rendered = @renderer.render_inlines(element.children, width: context.width)
        style = @renderer.style_for(style_name, fallback: yield(@renderer.theme_style(:text)))
        style.render(rendered)
      end

      # Renders a Markdown link as "label <href>" (URL omitted when empty), styled with
      # the markdown_link theme token or the info+underline fallback.
      def render_link(element, context)
        label = @renderer.render_inlines(element.children, width: context.width)
        href = element.attr["href"].to_s
        rendered = href.empty? ? label : "#{label} <#{href}>"
        @renderer.style_for(:markdown_link, fallback: @renderer.theme_style(:info).underline).render(rendered)
      end

      # Fallback for unknown inline types: returns the value when there are no children,
      # otherwise recurses into the children.
      def render_unknown(element, context)
        element.children.empty? ? element.value.to_s : @renderer.render_inlines(element.children, width: context.width)
      end
    end
  end
end
