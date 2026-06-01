# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      # Modal is a centered, boxed overlay with an optional title, help line, and body content.
      # The body may be a string, View, or Component; when it responds to `render`, its output
      # is used. The result is wrapped in a UI::Style border with padding.
      class Modal < Component
        # *content* is the modal body. *title* (optional) is rendered centered at the top.
        # *help* (optional) is rendered as a muted footer line. *width* is the modal's total width.
        # *style* overrides the default `theme.modal` style.
        def initialize(content:, title: nil, help: nil, width: 52, style: nil, theme: nil)
          super(theme: theme)
          @content = content
          @title = title
          @help = help
          @width = width
          @style = style
        end

        # Renders the modal as a bordered, padded string with the title and help lines stacked
        # above the content.
        def render
          box(column(*lines, gap: 1), style: modal_style)
        end

        private

        attr_reader :content, :title, :help, :width

        # Returns the array of non-nil lines: title, help, content.
        def lines
          [title_line, help_line, render_content].compact
        end

        # Returns the centered title line styled with the theme's title style, when a title was given.
        def title_line
          text(title, style: theme.title.align(:center).width(title_width)) if title
        end

        # Returns the help line styled with the theme's muted style, when help was given.
        def help_line
          text(help, style: theme.muted) if help
        end

        # Returns the rendered content string, calling `render` on the body when applicable.
        def render_content
          content.respond_to?(:render) ? render_component(content) : content.to_s
        end

        # Returns the modal's outer style: the user-provided style or `theme.modal` at the given width.
        def modal_style
          @style || theme.modal.width(width)
        end

        # Returns the title's display width, accounting for the modal's horizontal padding/border.
        def title_width
          [width - 8, 0].max
        end
      end
    end
  end
end
