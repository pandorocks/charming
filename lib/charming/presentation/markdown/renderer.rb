# frozen_string_literal: true

require "commonmarker"

module Charming
  module Markdown
    # Renderer parses CommonMark/GFM with Commonmarker and renders it as ANSI text.
    class Renderer
      DEFAULT_RULE_WIDTH = 40

      attr_reader :content, :width, :theme, :syntax_highlighting, :style, :base_url

      def initialize(content:, width: nil, theme: UI::Theme.default, syntax_highlighting: true, style: :dark, base_url: nil)
        @content = content
        @width = width
        @theme = theme || UI::Theme.default
        @syntax_highlighting = syntax_highlighting
        @style = StyleConfig.from(style)
        @base_url = base_url
      end

      def render
        context = RenderContext.from(
          width: width,
          style: style,
          base_url: base_url,
          source_lines: content.to_s.lines(chomp: true)
        )
        render_document(parse_document, context: context)
      end

      def render_blocks(elements, context:)
        elements.filter_map do |element|
          rendered = render_block(element, context: context)
          rendered unless rendered.to_s.empty?
        end.join("\n\n")
      end

      def render_inlines(elements, context:)
        elements.map { |element| render_inline(element, context: context) }.join
      end

      def wrap(value, width:)
        TextWrapper.new(width: width).wrap(value)
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

      def parse_document
        Commonmarker.parse(
          content.to_s,
          options: {
            extension: {
              autolink: true,
              description_lists: true,
              footnotes: true,
              strikethrough: true,
              table: true,
              tasklist: true
            }
          }
        )
      end

      def render_document(node, context:)
        document_style = context.style[:document]
        body = render_blocks(children_of(node), context: context.with(current_style: document_style))
        document_style.render(document_style.apply_block_layout(body))
      end

      def render_block(node, context:)
        case node.type
        when :paragraph
          render_paragraph(node, context: context)
        when :heading
          render_heading(node, context: context)
        when :block_quote
          render_block_quote(node, context: context)
        when :list
          render_list(node, context: context)
        when :code_block
          render_code_block(node, context: context)
        when :thematic_break
          render_rule(context: context)
        when :table
          render_table(node, context: context)
        when :html_block
          render_html_block(node, context: context)
        else
          render_blocks(children_of(node), context: context)
        end
      end

      def render_inline(node, context:)
        case node.type
        when :text
          context.current_style.inherit_visual(context.style[:text]).render(node.string_content)
        when :softbreak
          " "
        when :linebreak
          "\n"
        when :code
          context.inherit(:code).render(node.string_content)
        when :emph
          render_styled_inline(node, :emph, context: context)
        when :strong
          render_styled_inline(node, :strong, context: context)
        when :strikethrough
          render_styled_inline(node, :strikethrough, context: context)
        when :link
          render_link(node, context: context)
        when :image
          render_image(node, context: context)
        when :html_inline
          ""
        else
          render_inlines(children_of(node), context: context)
        end
      end

      def render_paragraph(node, context:)
        paragraph_style = context.current_style.inherit_visual(context.style[:paragraph])
        body = render_inlines(children_of(node), context: context.with(current_style: paragraph_style))
        render_block_with_style(paragraph_style, wrap(body, width: context.width))
      end

      def render_heading(node, context:)
        heading_style = context.current_style.inherit_visual(context.style.heading(node.header_level))
        body = render_inlines(children_of(node), context: context.with(current_style: heading_style))
        render_block_with_style(heading_style, wrap(body, width: context.width))
      end

      def render_block_quote(node, context:)
        quote_style = context.current_style.inherit_visual(context.style[:block_quote])
        quote_width = context.width ? [context.width - quote_indent_width(quote_style), 1].max : nil
        body = render_blocks(children_of(node), context: context.with(width: quote_width, current_style: quote_style))
        render_block_with_style(quote_style, body)
      end

      def render_list(node, context:)
        list_style = context.current_style.inherit_visual(context.style[:list])
        children_of(node).each_with_index.map do |item, index|
          render_list_item(item, index: index, ordered: node.list_type == :ordered, list: node, context: context.with(current_style: list_style))
        end.join("\n")
      end

      def render_list_item(node, index:, ordered:, list:, context:)
        marker_style = context.current_style.inherit_visual(context.style[ordered ? :enumeration : :item])
        marker = if node.type == :taskitem
          task_marker(node, context: context)
        elsif ordered
          "#{list.list_start.to_i + index}. "
        else
          marker_style.block_prefix.empty? ? "- " : marker_style.block_prefix
        end

        indent = " " * (context.style[:list].level_indent || 2) * context.list_depth
        first_prefix = "#{indent}#{marker}"
        rest_prefix = "#{indent}#{" " * UI::Width.measure(marker)}"
        item_width = context.width ? [context.width - UI::Width.measure(first_prefix), 1].max : nil
        body = render_blocks(children_of(node), context: context.nested_list(width: item_width))

        body.lines(chomp: true).each_with_index.map do |line, line_index|
          "#{line_index.zero? ? first_prefix : rest_prefix}#{line}"
        end.join("\n")
      end

      def task_marker(node, context:)
        task_style = context.current_style.inherit_visual(context.style[:task])
        checked_task?(node, context: context) ? (task_style.ticked || "[x] ") : (task_style.unticked || "[ ] ")
      end

      def checked_task?(node, context:)
        line = context.source_lines[node.source_position[:start_line].to_i - 1].to_s
        line.match?(/\[[xX]\]/)
      end

      def render_code_block(node, context:)
        code_style = context.current_style.inherit_visual(context.style[:code_block])
        code = node.string_content.to_s.chomp
        rendered = if syntax_highlighting
          SyntaxHighlighter.new(theme: theme, style: style).render(code, language: node.fence_info.to_s.split.first)
        else
          code_style.render(code)
        end

        body = rendered.lines(chomp: true).map { |line| "  #{line}" }.join("\n")
        syntax_highlighting ? code_style.apply_block_layout(body) : render_block_with_style(code_style, body)
      end

      def render_rule(context:)
        rule_style = context.current_style.inherit_visual(context.style[:hr])
        body = rule_style.format.empty? ? "-" * (context.width || DEFAULT_RULE_WIDTH) : rule_style.format
        render_block_with_style(rule_style, body)
      end

      def render_table(node, context:)
        table_style = context.current_style.inherit_visual(context.style[:table])
        rows = children_of(node).map do |row|
          children_of(row).map { |cell| render_inlines(children_of(cell), context: context.with(current_style: table_style)) }
        end

        body = TableRenderer.new(rows: rows, style: table_style).render
        return "" if body.empty?

        render_block_with_style(table_style, body)
      end

      def render_html_block(_node, context:)
        html_style = context.current_style.inherit_visual(context.style[:html_block])
        return "" if html_style.format.empty?

        render_block_with_style(html_style, html_style.format)
      end

      def render_styled_inline(node, style_name, context:)
        inline_style = context.inherit(style_name)
        inline_style.render(render_inlines(children_of(node), context: context.with(current_style: inline_style)))
      end

      def render_link(node, context:)
        href = resolve_url(node.url.to_s, context: context)
        text_style = context.inherit(:link_text)
        link_style = context.inherit(:link)
        label = render_inlines(children_of(node), context: context.with(current_style: text_style))
        rendered = if href.empty? || UI::Width.strip_ansi(label) == href
          label
        else
          "#{label} <#{href}>"
        end
        link_style.render(rendered)
      end

      def render_image(node, context:)
        href = resolve_url(node.url.to_s, context: context)
        image_style = context.inherit(:image)
        text_style = context.inherit(:image_text)
        alt = render_inlines(children_of(node), context: context.with(current_style: text_style))
        label = if text_style.format.empty?
          "Image: #{UI::Width.strip_ansi(alt)} ->"
        else
          text_style.format.gsub("{{text}}", UI::Width.strip_ansi(alt))
        end

        image_style.render([label, href].reject(&:empty?).join(" "))
      end

      def render_block_with_style(style, body)
        style.render(style.apply_block_layout(body))
      end

      def quote_indent_width(style)
        return 0 unless style.indent&.positive?

        UI::Width.measure((style.indent_token || " ") * style.indent)
      end

      def resolve_url(value, context:)
        URLResolver.new(base_url: context.base_url).resolve(value)
      end

      def children_of(node)
        node.each.to_a
      end
    end
  end
end
