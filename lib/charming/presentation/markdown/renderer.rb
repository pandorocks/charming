# frozen_string_literal: true

require "kramdown"

module Charming
  module Presentation
    module Markdown
      class Renderer
        DEFAULT_RULE_WIDTH = 40

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

        private

        attr_reader :content, :width, :theme

        def render_blocks(elements, list_depth: 0, width: @width)
          elements.filter_map do |element|
            rendered = render_block(element, list_depth: list_depth, width: width)
            rendered unless rendered.to_s.empty?
          end.join("\n\n")
        end

        def render_block(element, list_depth: 0, width: @width)
          case element.type
          when :p
            wrap(render_inlines(element.children), width: width)
          when :header
            render_header(element, width: width)
          when :blockquote
            render_blockquote(element, list_depth: list_depth, width: width)
          when :ul
            render_list(element, ordered: false, list_depth: list_depth, width: width)
          when :ol
            render_list(element, ordered: true, list_depth: list_depth, width: width)
          when :li
            render_blocks(element.children, list_depth: list_depth, width: width)
          when :codeblock
            render_codeblock(element)
          when :hr
            render_rule(width: width)
          when :blank
            nil
          else
            render_unknown(element, list_depth: list_depth, width: width)
          end
        end

        def render_unknown(element, list_depth:, width:)
          return wrap(element.value.to_s, width: width) if element.children.empty?

          render_blocks(element.children, list_depth: list_depth, width: width)
        end

        def render_header(element, width:)
          rendered = wrap(render_inlines(element.children), width: width)
          style = if element.options[:level].to_i == 1
            style_for(:markdown_heading, fallback: theme_style(:title))
          else
            style_for(:markdown_subheading, fallback: theme_style(:title))
          end
          style.render(rendered)
        end

        def render_blockquote(element, list_depth:, width:)
          quote_width = width ? [width - 2, 1].max : nil
          rendered = render_blocks(element.children, list_depth: list_depth, width: quote_width)
          border = style_for(:markdown_quote_border, fallback: theme_style(:border)).render("|")
          quote_style = style_for(:markdown_quote, fallback: theme_style(:muted))

          rendered.lines(chomp: true).map do |line|
            "#{border} #{quote_style.render(line)}"
          end.join("\n")
        end

        def render_list(element, ordered:, list_depth:, width:)
          element.children.each_with_index.map do |item, index|
            marker = ordered ? "#{ordered_start(element) + index}." : "-"
            render_list_item(item, marker: marker, list_depth: list_depth, width: width)
          end.join("\n")
        end

        def render_list_item(element, marker:, list_depth:, width:)
          indent = "  " * list_depth
          first_prefix = "#{indent}#{marker} "
          rest_prefix = "#{indent}#{" " * (marker.length + 1)}"
          item_width = width ? [width - UI::Width.measure(first_prefix), 1].max : nil
          body = render_blocks(element.children, list_depth: list_depth + 1, width: item_width)

          body.lines(chomp: true).each_with_index.map do |line, index|
            "#{index.zero? ? first_prefix : rest_prefix}#{line}"
          end.join("\n")
        end

        def ordered_start(element)
          element.options.fetch(:start, 1).to_i
        end

        def render_codeblock(element)
          code = element.value.to_s
          rendered = if @syntax_highlighting
            SyntaxHighlighter.new(theme: theme).render(code, language: code_language(element))
          else
            style_for(:markdown_code, fallback: theme_style(:warn)).render(code)
          end

          rendered.lines(chomp: true).map { |line| "  #{line}" }.join("\n")
        end

        def render_rule(width:)
          style_for(:markdown_rule, fallback: theme_style(:border)).render("-" * (width || DEFAULT_RULE_WIDTH))
        end

        def render_inlines(elements)
          elements.map { |element| render_inline(element) }.join
        end

        def render_inline(element)
          case element.type
          when :text
            element.value.to_s
          when :strong
            style_for(:markdown_strong, fallback: theme_style(:text).bold).render(render_inlines(element.children))
          when :em
            style_for(:markdown_emphasis, fallback: theme_style(:text).italic).render(render_inlines(element.children))
          when :codespan
            style_for(:markdown_inline_code, fallback: theme_style(:warn)).render(element.value.to_s)
          when :a
            render_link(element)
          when :br
            "\n"
          when :entity
            element.value.respond_to?(:char) ? element.value.char : element.value.to_s
          else
            element.children.empty? ? element.value.to_s : render_inlines(element.children)
          end
        end

        def render_link(element)
          label = render_inlines(element.children)
          href = element.attr["href"].to_s
          rendered = href.empty? ? label : "#{label} <#{href}>"
          style_for(:markdown_link, fallback: theme_style(:info).underline).render(rendered)
        end

        def code_language(element)
          return element.options[:lang] if element.options[:lang]

          element.attr["class"].to_s[/language-([^\s]+)/, 1]
        end

        def wrap(value, width:)
          return value unless width

          value.to_s.lines(chomp: true).map { |line| wrap_line(line, width) }.join("\n")
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

        def style_for(name, fallback:)
          return theme.public_send(name) if theme.respond_to?(name)

          fallback
        end

        def theme_style(name)
          return theme.public_send(name) if theme.respond_to?(name)

          UI::Theme::DEFAULT_TOKENS.fetch(name).then { |token| UI::Theme.new(name => token).public_send(name) }
        end
      end
    end
  end
end
