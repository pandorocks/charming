# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      class Pane
        attr_reader :name, :width, :height, :grow

        def initialize(name: nil, content: nil, block: nil, view: nil, width: nil, height: nil, grow: nil, border: nil, padding: nil, style: nil, focused_style: nil, focus: false, scroll: false, clip: true, wrap: false)
          @name = name
          @content = content
          @block = block
          @view = view
          @width = width
          @height = height
          @grow = grow
          @border = border
          @padding = padding
          @style = style
          @focused_style = focused_style
          @focus = focus
          @scroll = scroll
          @clip = clip
          @wrap = wrap
        end

        def add_child(_node)
          raise ArgumentError, "pane cannot contain layout children"
        end

        def focusable_names
          (focus && name) ? [name] : []
        end

        def render(rect)
          outer_style(rect).render(rendered_content(rect))
        end

        private

        attr_reader :content, :block, :view, :border, :padding, :style, :focused_style, :focus, :scroll, :clip, :wrap

        def rendered_content(rect)
          value = evaluate_content
          return value unless clip || scroll

          Components::Viewport.new(content: value, width: inner_rect(rect).width, height: inner_rect(rect).height, wrap: wrap).render
        end

        def evaluate_content
          value = block ? view.instance_exec(&block) : content
          value.respond_to?(:render) ? value.render.to_s : value.to_s
        end

        def outer_style(rect)
          styled = current_style
          styled = styled.border(border_style) if border
          styled = styled.padding(*padding_values) if padding
          styled.width(inner_rect(rect).width).height(inner_rect(rect).height)
        end

        def current_style
          return focused_pane_style if focused?

          style || UI.style
        end

        def focused_pane_style
          focused_style || view.__send__(:theme).title
        end

        def focused?
          focus && name && view.focused?(name)
        end

        def inner_rect(rect)
          rect.inset(
            top: border_top + padding_top,
            right: border_right + padding_right,
            bottom: border_bottom + padding_bottom,
            left: border_left + padding_left
          )
        end

        def border_style
          (border == true) ? :normal : border
        end

        def border_top = border ? 1 : 0

        def border_right = border ? 1 : 0

        def border_bottom = border ? 1 : 0

        def border_left = border ? 1 : 0

        def padding_values
          @padding_values ||= expand_padding(Array(padding))
        end

        def padding_top = padding ? padding_values[0] : 0

        def padding_right = padding ? padding_values[1] : 0

        def padding_bottom = padding ? padding_values[2] : 0

        def padding_left = padding ? padding_values[3] : 0

        def expand_padding(values)
          case values.length
          when 1 then [values[0], values[0], values[0], values[0]]
          when 2 then [values[0], values[1], values[0], values[1]]
          when 4 then values
          else
            raise ArgumentError, "padding expects 1, 2, or 4 values"
          end
        end
      end
    end
  end
end
