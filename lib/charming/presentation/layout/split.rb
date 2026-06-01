# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      # Split divides a parent Rect among its child nodes horizontally or vertically.
      # Children with a configured `width`/`height` are placed at that fixed size; children
      # without a fixed size share the remaining space according to their `grow` weight.
      class Split
        # The fixed width/height of the split (when set) and the grow weight for the split itself.
        attr_reader :width, :height, :grow

        # *direction* is `:horizontal` or `:vertical`. *gap* (in cells) separates children.
        # *width*/*height* are optional fixed dimensions for the split as a whole.
        # *grow* is the weight for distributing remaining space (used when this Split is a
        # child of another Split).
        def initialize(direction:, gap: 0, width: nil, height: nil, grow: nil)
          @direction = direction.to_sym
          @gap = gap.to_i
          @width = width
          @height = height
          @grow = grow
          @children = []
        end

        # Appends *node* (a child Split or Pane) to this Split.
        def add_child(node)
          children << node
        end

        # Returns the flattened list of focusable names from all child nodes.
        def focusable_names
          children.flat_map(&:focusable_names)
        end

        # Renders each child into its own sub-rect, then overlays them on a blank canvas
        # of the parent's dimensions.
        def render(rect)
          frame = UI.place("", width: rect.width, height: rect.height)

          child_rects(rect).zip(children).each do |child_rect, child|
            frame = UI.overlay(frame, child.render(child_rect), top: child_rect.y - rect.y, left: child_rect.x - rect.x)
          end

          frame
        end

        private

        # The split direction (`:horizontal` or `:vertical`) and the inter-child gap.
        attr_reader :direction, :gap, :children

        # Returns an array of child rects sized according to each child's fixed dimensions
        # and grow weights. Raises ArgumentError when *direction* is neither horizontal nor vertical.
        def child_rects(rect)
          return horizontal_rects(rect) if direction == :horizontal
          return vertical_rects(rect) if direction == :vertical

          raise ArgumentError, "unknown split direction: #{direction.inspect}"
        end

        # Computes per-child rects for a horizontal split.
        def horizontal_rects(rect)
          sizes = child_sizes(axis: :horizontal, available: rect.width)
          left = rect.x

          sizes.map do |width|
            child_rect = Rect.new(x: left, y: rect.y, width: width, height: rect.height)
            left += width + gap
            child_rect
          end
        end

        # Computes per-child rects for a vertical split.
        def vertical_rects(rect)
          sizes = child_sizes(axis: :vertical, available: rect.height)
          top = rect.y

          sizes.map do |height|
            child_rect = Rect.new(x: rect.x, y: top, width: rect.width, height: height)
            top += height + gap
            child_rect
          end
        end

        # Computes the size of each child along the *axis* given the *available* cells.
        # Subtracts the total gap, allocates fixed sizes first, and distributes the remainder
        # among flexible (non-fixed) children by their grow weights.
        def child_sizes(axis:, available:)
          gap_size = gap * [children.length - 1, 0].max
          available_for_children = [available - gap_size, 0].max
          fixed = children.map { |child| fixed_size(child, axis) }
          flexible_indexes = fixed.each_index.select { |index| fixed[index].nil? }
          sizes = fixed.map { |size| size&.to_i }
          remaining = [available_for_children - sizes.compact.sum, 0].max

          distribute_remaining(sizes, flexible_indexes, remaining)
        end

        # Returns the fixed size of *child* along *axis* (`:horizontal` reads width, `:vertical` reads height).
        def fixed_size(child, axis)
          (axis == :horizontal) ? child.width : child.height
        end

        # Distributes the *remaining* cells across *flexible_indexes* by grow weight, with the
        # last flexible child absorbing any rounding remainder.
        def distribute_remaining(sizes, flexible_indexes, remaining)
          return sizes.map { |size| size || 0 } if flexible_indexes.empty?

          total_grow = flexible_indexes.sum { |index| grow_weight(children[index]) }
          used = 0

          flexible_indexes.each_with_index do |index, flexible_index|
            size = if flexible_index == flexible_indexes.length - 1
              remaining - used
            else
              (remaining * grow_weight(children[index]) / total_grow).floor
            end

            sizes[index] = size
            used += size
          end

          sizes
        end

        # Returns the grow weight of *child*, defaulting to 1 when unset.
        def grow_weight(child)
          [child.grow.to_i, 1].max
        end
      end
    end
  end
end
