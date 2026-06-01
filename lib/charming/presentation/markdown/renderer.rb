# frozen_string_literal: true

require "kramdown"

module Charming
  module Presentation
    module Markdown
      # Renderer is the top-level Markdown-to-ANSI renderer. Parses the *content* with
      # Kramdown, then walks the document's block and inline trees to produce styled
      # terminal output. Code blocks are highlighted via Rouge when `syntax_highlighting`
      # is enabled.
      class Renderer
        # Wrap width used by `render_rule` when no width is otherwise specified.
        DEFAULT_RULE_WIDTH = 40

        # The Markdown source, configured wrap width, theme, and syntax-highlighting flag.
        attr_reader :content, :width, :theme, :syntax_highlighting

        # *content* is the Markdown source string. *width* optionally wraps paragraphs to that
        # many display columns. *theme* is the Charming theme used to style blocks/inlines.
        # *syntax_highlighting* enables Rouge-backed code block highlighting (default true).
        def initialize(content:, width: nil, theme: UI::Theme.default, syntax_highlighting: true)
          @content = content
          @width = width
          @theme = theme || UI::Theme.default
          @syntax_highlighting = syntax_highlighting
        end

        # Parses the content and returns the fully-rendered Markdown as a single string.
        def render
          document = Kramdown::Document.new(content.to_s)
          render_blocks(document.root.children)
        end

        # Renders a list of Kramdown block *elements* into a string, joined by blank lines.
        # *list_depth* is forwarded to the render context for list indentation. *width*
        # defaults to the renderer's configured width.
        def render_blocks(elements, list_depth: 0, width: @width)
          context = RenderContext.from(width: width, list_depth: list_depth)
          elements.filter_map do |element|
            rendered = block_renderer.render(element, context: context)
            rendered unless rendered.to_s.empty?
          end.join("\n\n")
        end

        # Renders a list of Kramdown inline *elements* into a single concatenated string.
        # *width* defaults to the renderer's configured width.
        def render_inlines(elements, width: @width)
          context = RenderContext.from(width: width)
          elements.map { |element| inline_renderer.render(element, context: context) }.join
        end

        # Word-wraps *value* to *width* display columns (when *width* is given), preserving
        # any ANSI styling on each line. Returns *value* unchanged when *width* is nil.
        def wrap(value, width:)
          return value unless width

          value.to_s.lines(chomp: true).map { |line| wrap_line(line, width) }.join("\n")
        end

        # Returns the theme's style for *name* if the theme defines it, otherwise returns
        # *fallback*. Lets views override markdown-specific theme tokens.
        def style_for(name, fallback:)
          return theme.public_send(name) if theme.respond_to?(name)

          fallback
        end

        # Returns the theme's style for *name*, building a one-token default theme when
        # the active theme doesn't define it. Used as a final fallback for markdown styling.
        def theme_style(name)
          return theme.public_send(name) if theme.respond_to?(name)

          UI::Theme::DEFAULT_TOKENS.fetch(name).then { |token| UI::Theme.new(name => token).public_send(name) }
        end

        private

        # The BlockRenderer instance, lazily built.
        def block_renderer
          @block_renderer ||= BlockRenderer.new(renderer: self)
        end

        # The InlineRenderer instance, lazily built.
        def inline_renderer
          @inline_renderer ||= InlineRenderer.new(renderer: self)
        end

        # Word-wraps a single *line* to *width* display columns using greedy space-splitting.
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
