# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      # Pane is a leaf layout node: a single rectangle with optional border, padding, and
      # styling, containing a piece of content (a string, a View, or a block evaluated in the
      # view's context). Panes with a `name` and `focus: true` are registered as focusable
      # slots in the controller's focus ring.
      class Pane
        # The pane's focus slot name, fixed width, fixed height, and grow weight.
        attr_reader :name, :width, :height, :grow

        # *name* is the focus slot identifier (optional). *content* or *block* provides the body.
        # *width*/*height*/*grow* control sizing. *border* may be `true` (normal border) or a
        # border name symbol. *padding* may be 1, 2, or 4 values (CSS-style shorthand).
        # *style* sets the base style; *focused_style* overrides it when the pane is focused.
        # *focus: true* marks the pane as focusable. *scroll*/*clip*/*wrap* control how
        # overflow content is rendered (via the embedded Viewport).
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

        # Raises ArgumentError — panes are leaves and cannot contain layout children.
        def add_child(_node)
          raise ArgumentError, "pane cannot contain layout children"
        end

        # Returns [name] when the pane is marked focusable and has a name, otherwise [].
        def focusable_names
          (focus && name) ? [name] : []
        end

        # Renders the pane into *rect*, applying the configured style, border, and padding
        # around the evaluated content.
        def render(rect)
          outer_style(rect).render(rendered_content(rect))
        end

        private

        # The raw content, the body block, the view used for instance_exec, and styling options.
        attr_reader :content, :block, :view, :border, :padding, :style, :focused_style, :focus, :scroll, :clip, :wrap

        # Returns the content string for *rect*, optionally clipped/scrolled by an embedded Viewport.
        def rendered_content(rect)
          value = evaluate_content
          return value unless clip || scroll

          Components::Viewport.new(content: value, width: inner_rect(rect).width, height: inner_rect(rect).height, wrap: wrap).render
        end

        # Evaluates the configured content (block or constant) and renders it to a string.
        def evaluate_content
          value = block ? view.instance_exec(&block) : content
          value.respond_to?(:render) ? value.render.to_s : value.to_s
        end

        # Builds the outer style object with optional border and padding, sized to the
        # inner rect of the pane.
        def outer_style(rect)
          styled = current_style
          styled = styled.border(border_style) if border
          styled = styled.padding(*padding_values) if padding
          styled.width(inner_rect(rect).width).height(inner_rect(rect).height)
        end

        # Returns the active style: the focused variant when the pane is focused, otherwise
        # the configured style or a default UI::Style.
        def current_style
          return focused_pane_style if focused?

          style || UI.style
        end

        # Returns the focused-pane style: the focused_style override, or the theme's title style.
        def focused_pane_style
          focused_style || view.__send__(:theme).title
        end

        # True when the pane is configured for focus and the view reports it as currently focused.
        def focused?
          focus && name && view.focused?(name)
        end

        # Returns the inner Rect after border and padding insets are applied.
        def inner_rect(rect)
          rect.inset(
            top: border_top + padding_top,
            right: border_right + padding_right,
            bottom: border_bottom + padding_bottom,
            left: border_left + padding_left
          )
        end

        # Resolves the border style symbol: :normal when border is `true`, otherwise the configured value.
        def border_style
          (border == true) ? :normal : border
        end

        # Border thickness on each side (1 when a border is configured, 0 otherwise).
        def border_top = border ? 1 : 0
        def border_right = border ? 1 : 0
        def border_bottom = border ? 1 : 0
        def border_left = border ? 1 : 0

        # The padding values normalized to [top, right, bottom, left] form.
        def padding_values
          @padding_values ||= expand_padding(Array(padding))
        end

        # Per-side padding values (0 when no padding is configured).
        def padding_top = padding ? padding_values[0] : 0
        def padding_right = padding ? padding_values[1] : 0
        def padding_bottom = padding ? padding_values[2] : 0
        def padding_left = padding ? padding_values[3] : 0

        # Normalizes 1/2/4 padding arguments to [top, right, bottom, left].
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
