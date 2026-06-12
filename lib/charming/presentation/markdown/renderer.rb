# frozen_string_literal: true

require "commonmarker"

module Charming
  module Markdown
    # Renderer parses CommonMark/GFM with Commonmarker and renders it as ANSI text.
    class Renderer
      DEFAULT_RULE_WIDTH = 40

      attr_reader :content, :width, :theme, :syntax_highlighting, :style, :base_url, :hyperlinks

      # *hyperlinks* (default false) wraps links in OSC 8 escape sequences so modern
      # terminals make them clickable; the ` <url>` suffix is omitted since the target
      # is embedded in the escape.
      def initialize(content:, width: nil, theme: UI::Theme.default, syntax_highlighting: true, style: :dark, base_url: nil, hyperlinks: false)
        @content = content
        @width = width
        @theme = theme || UI::Theme.default
        @syntax_highlighting = syntax_highlighting
        @style = StyleConfig.from(style)
        @base_url = base_url
        @hyperlinks = hyperlinks
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
        when :description_list
          render_definition_list(node, context: context)
        when :footnote_definition
          render_footnote_definition(node, context: context)
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
        when :footnote_reference
          render_footnote_reference(node, context: context)
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

      # Matches a checked task marker anchored to the list-item prefix, so prose that
      # merely mentions "[x]" can't check the box.
      TASK_CHECKED_PATTERN = /\A\s*(?:[-*+]|\d+[.)])\s+\[[xX]\]/

      # Commonmarker exposes no checked-state accessor on taskitem nodes, so the
      # original source line is inspected instead.
      def checked_task?(node, context:)
        line = context.source_lines[node.source_position[:start_line].to_i - 1].to_s
        line.match?(TASK_CHECKED_PATTERN)
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
        available_width = context.width || DEFAULT_RULE_WIDTH
        padding = rule_style.indent.to_i * 2
        rule_width = [available_width - padding, 1].max
        body = repeat_to_width(rule_style.format.empty? ? "-" : rule_style.format, rule_width)
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

      # Renders `Term / : definition` description lists: terms in the definition_term
      # style, details indented per the definition_description style.
      def render_definition_list(node, context:)
        children_of(node).map { |item| render_definition_item(item, context: context) }.join("\n")
      end

      def render_definition_item(node, context:)
        parts = children_of(node).map do |child|
          case child.type
          when :description_term
            render_definition_term(child, context: context)
          when :description_details
            render_definition_details(child, context: context)
          else
            render_block(child, context: context)
          end
        end
        parts.reject { |part| part.to_s.empty? }.join("\n")
      end

      def render_definition_term(node, context:)
        term_style = context.current_style.inherit_visual(context.style[:definition_term])
        term_style.render(render_inlines(children_of(node), context: context.with(current_style: term_style)))
      end

      def render_definition_details(node, context:)
        details_style = context.current_style.inherit_visual(context.style[:definition_description])
        indent = " " * (details_style.indent || 4)
        details_width = context.width ? [context.width - indent.length, 1].max : nil
        body = render_blocks(children_of(node), context: context.with(width: details_width, current_style: details_style))
        body.lines(chomp: true).map { |line| "#{indent}#{line}" }.join("\n")
      end

      # Renders an inline `[^name]` reference as a bracketed label in the link style.
      def render_footnote_reference(node, context:)
        context.inherit(:link).render("[#{footnote_name(node)}]")
      end

      # Renders a footnote definition as a labeled block with hanging indentation.
      def render_footnote_definition(node, context:)
        label_style = context.current_style.inherit_visual(context.style[:link_text])
        label = "[#{footnote_name(node)}]: "
        indent = " " * UI::Width.measure(label)
        body_width = context.width ? [context.width - UI::Width.measure(label), 1].max : nil
        body = render_blocks(children_of(node), context: context.with(width: body_width))
        lines = body.lines(chomp: true)
        return label_style.render(label.rstrip) if lines.empty?

        first = "#{label_style.render(label)}#{lines.first}"
        rest = lines.drop(1).map { |line| "#{indent}#{line}" }
        [first, *rest].join("\n")
      end

      # Commonmarker exposes no name accessor on footnote nodes; the round-tripped
      # commonmark source (`"[^name]\n"` / `"[^name]:\n..."`) carries the label.
      def footnote_name(node)
        node.to_commonmark[/\A\[\^(.+?)\]/, 1].to_s
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
        return osc8_hyperlink(href, link_style.render(label)) if hyperlinks && !href.empty?

        rendered = if href.empty? || UI::Width.strip_ansi(label) == href
          label
        else
          "#{label} <#{href}>"
        end
        link_style.render(rendered)
      end

      # Wraps *rendered* in an OSC 8 hyperlink to *href*. Modern terminals make the
      # text clickable; the sequence is invisible to width math (UI::Width strips OSC).
      def osc8_hyperlink(href, rendered)
        "\e]8;;#{href}\e\\#{rendered}\e]8;;\e\\"
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

      def repeat_to_width(value, width)
        token = value.to_s
        token_width = [UI::Width.measure(token), 1].max
        repeated = token * ((width.to_i + token_width - 1) / token_width)
        UI.visible_slice(repeated, 0, width)
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
