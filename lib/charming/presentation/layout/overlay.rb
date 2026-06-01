# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      class Overlay
        attr_reader :top, :left

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

        def render
          return styled_content unless width || height

          UI.place(styled_content, width: width || UI.block_width(styled_content.lines(chomp: true)), height: height || styled_content.lines.count)
        end

        private

        attr_reader :content, :block, :view, :width, :height, :style

        def styled_content
          return rendered_content unless style

          style.render(rendered_content)
        end

        def rendered_content
          value = block ? view.instance_exec(&block) : content
          value.respond_to?(:render) ? value.render.to_s : value.to_s
        end
      end
    end
  end
end
