# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      # Overlay is a compositing node used by ScreenLayout for floating elements (modals,
      # dialogs, command palettes). It positions its content at *top*/*left* (each may be
      # `:center` or an absolute cell offset) and optionally sizes it via *width*/*height*
      # with an outer *style*.
      class Overlay
        # The vertical and horizontal offset (cell count or `:center`) of the overlay
        # within the parent canvas.
        attr_reader :top, :left

        # *content* (or a *block*) provides the body. *top*/*left* default to :center.
        # *width*/*height* fix the overlay's dimensions; when unset, the content's natural
        # size is used. *style* wraps the rendered content in a UI::Style.
        def initialize(content: nil, block: nil, view: nil, top: :center, left: :center, width: nil, height: nil, style: nil)
          @content = content
          @block = block
          @view = view
          @top = top
          @left = left
          @width = width
          @height = height
          @style = style
        end

        # Renders the overlay's content; when *width* or *height* is set, places the rendered
        # content into a sized canvas before returning.
        def render
          return styled_content unless width || height

          UI.place(styled_content, width: width || UI.block_width(styled_content.lines(chomp: true)), height: height || styled_content.lines.count)
        end

        private

        # The raw content, body block, view, and sizing/style options.
        attr_reader :content, :block, :view, :width, :height, :style

        # Returns the rendered content wrapped in the configured *style* (when present).
        def styled_content
          return rendered_content unless style

          style.render(rendered_content)
        end

        # Evaluates the content (block or constant) and returns its rendered string.
        def rendered_content
          value = block ? view.instance_exec(&block) : content
          value.respond_to?(:render) ? value.render.to_s : value.to_s
        end
      end
    end
  end
end
