# frozen_string_literal: true

module Charming
  module Markdown
    # BlockRenderer dispatches Kramdown block-level elements (paragraph, header, list,
    # code block, etc.) to their individual rendering handlers. Handlers are built once
    # at construction time as a frozen hash of element-type symbols to callables.
    class BlockRenderer
      # *renderer* is the parent Renderer (used to wrap text, render inlines, and look up styles).
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

      # Builds the handler hash. Each handler is a small lambda that calls back into the
      # parent renderer (or one of the private render_* methods below).
      def build_handlers
        r = @renderer
        @handlers = {
          p: ->(element, context) { r.wrap(r.render_inlines(element.children), width: context.width) },
          header: ->(element, context) { send(:render_header, element, context) },
          blockquote: ->(element, context) { send(:render_blockquote, element, context) },
          ul: ->(element, context) { send(:render_list, element, ordered: false, context: context) },
          ol: ->(element, context) { send(:render_list, element, ordered: true, context: context) },
          li: ->(element, context) { r.render_blocks(element.children, list_depth: context.list_depth, width: context.width) },
          codeblock: ->(element, _context) { send(:render_codeblock, element) },
          hr: ->(element, context) { send(:render_rule, width: context.width) },
          blank: ->(_element, _context) {}
        }.freeze
      end

      # Fallback for unknown block types: wraps the raw value when there are no children,
      # otherwise recurses into the children.
      def render_unknown(element, context)
        return @renderer.wrap(element.value.to_s, width: context.width) if element.children.empty?

        @renderer.render_blocks(element.children, list_depth: context.list_depth, width: context.width)
      end

      # Renders a header element, using the `markdown_heading` style for h1 and the
      # `markdown_subheading` style for h2+.
      def render_header(element, context)
        rendered = @renderer.wrap(@renderer.render_inlines(element.children), width: context.width)
        style = if element.options[:level].to_i == 1
          @renderer.style_for(:markdown_heading, fallback: @renderer.theme_style(:title))
        else
          @renderer.style_for(:markdown_subheading, fallback: @renderer.theme_style(:title))
        end
        style.render(rendered)
      end

      def render_blockquote(element, context)
        quote_width = context.width ? [context.width - 2, 1].max : nil
        rendered = @renderer.render_blocks(element.children, list_depth: context.list_depth, width: quote_width)
        border = @renderer.style_for(:markdown_quote_border, fallback: @renderer.theme_style(:border)).render("|")
        quote_style = @renderer.style_for(:markdown_quote, fallback: @renderer.theme_style(:muted))

        rendered.lines(chomp: true).map { |line| "#{border} #{quote_style.render(line)}" }.join("\n")
      end

      def render_list(element, ordered:, context:)
        element.children.each_with_index.map do |item, index|
          marker = ordered ? "#{ordered_start(element) + index}." : "-"
          render_list_item(item, marker: marker, context: context)
        end.join("\n")
      end

      def render_list_item(element, marker:, context:)
        indent = "  " * context.list_depth
        first_prefix = "#{indent}#{marker} "
        rest_prefix = "#{indent}#{" " * (marker.length + 1)}"
        item_width = context.width ? [context.width - UI::Width.measure(first_prefix), 1].max : nil
        body = @renderer.render_blocks(element.children, list_depth: context.list_depth + 1, width: item_width)

        body.lines(chomp: true).each_with_index.map do |line, index|
          "#{index.zero? ? first_prefix : rest_prefix}#{line}"
        end.join("\n")
      end

      def ordered_start(element)
        element.options.fetch(:start, 1).to_i
      end

      def render_codeblock(element)
        code = element.value.to_s
        rendered = if @renderer.syntax_highlighting
          SyntaxHighlighter.new(theme: @renderer.theme).render(code, language: code_language(element))
        else
          @renderer.style_for(:markdown_code, fallback: @renderer.theme_style(:warn)).render(code)
        end

        rendered.lines(chomp: true).map { |line| "  #{line}" }.join("\n")
      end

      def render_rule(width:)
        @renderer.style_for(:markdown_rule, fallback: @renderer.theme_style(:border)).render("-" * (width || Renderer::DEFAULT_RULE_WIDTH))
      end

      def code_language(element)
        return element.options[:lang] if element.options[:lang]

        element.attr["class"].to_s[/language-([^\s]+)/, 1]
      end
    end
  end
end
