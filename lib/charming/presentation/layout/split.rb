# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      class Split
        attr_reader :width, :height, :grow

        def initialize(direction:, gap: 0, width: nil, height: nil, grow: nil)
          @direction = direction.to_sym
          @gap = gap.to_i
          @width = width
          @height = height
          @grow = grow
          @children = []
        end

        def add_child(node)
          children << node
        end

        def focusable_names
          children.flat_map(&:focusable_names)
        end

        def render(rect)
          frame = UI.place("", width: rect.width, height: rect.height)

          child_rects(rect).zip(children).each do |child_rect, child|
            frame = UI.overlay(frame, child.render(child_rect), top: child_rect.y - rect.y, left: child_rect.x - rect.x)
          end

          frame
        end

        private

        attr_reader :direction, :gap, :children

        def child_rects(rect)
          return horizontal_rects(rect) if direction == :horizontal
          return vertical_rects(rect) if direction == :vertical

          raise ArgumentError, "unknown split direction: #{direction.inspect}"
        end

        def horizontal_rects(rect)
          sizes = child_sizes(axis: :horizontal, available: rect.width)
          left = rect.x

          sizes.map do |width|
            child_rect = Rect.new(x: left, y: rect.y, width: width, height: rect.height)
            left += width + gap
            child_rect
          end
        end

        def vertical_rects(rect)
          sizes = child_sizes(axis: :vertical, available: rect.height)
          top = rect.y

          sizes.map do |height|
            child_rect = Rect.new(x: rect.x, y: top, width: rect.width, height: height)
            top += height + gap
            child_rect
          end
        end

        def child_sizes(axis:, available:)
          gap_size = gap * [children.length - 1, 0].max
          available_for_children = [available - gap_size, 0].max
          fixed = children.map { |child| fixed_size(child, axis) }
          flexible_indexes = fixed.each_index.select { |index| fixed[index].nil? }
          sizes = fixed.map { |size| size&.to_i }
          remaining = [available_for_children - sizes.compact.sum, 0].max

          distribute_remaining(sizes, flexible_indexes, remaining)
        end

        def fixed_size(child, axis)
          (axis == :horizontal) ? child.width : child.height
        end

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

        def grow_weight(child)
          [child.grow.to_i, 1].max
        end
      end
    end
  end
end
