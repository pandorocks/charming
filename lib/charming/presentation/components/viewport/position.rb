# frozen_string_literal: true

module Charming
  module Components
    class Viewport
      # Position owns the viewport's mutable row and column offsets.
      class Position
        attr_reader :offset, :column

        def initialize(offset:, column:)
          @offset = offset
          @column = column
        end

        def scroll_up(bounds)
          @offset -= 1
          clamp(bounds)
        end

        def scroll_down(bounds)
          @offset += 1
          clamp(bounds)
        end

        def page_up(page_size, bounds)
          @offset -= page_size
          clamp(bounds)
        end

        def page_down(page_size, bounds)
          @offset += page_size
          clamp(bounds)
        end

        def home
          @offset = 0
          @column = 0
        end

        def end_at(bounds)
          @offset = bounds.fetch(:max_offset)
          @column = bounds.fetch(:max_column)
        end

        def scroll_left(bounds)
          @column -= 1
          clamp(bounds)
        end

        def scroll_right(bounds)
          @column += 1
          clamp(bounds)
        end

        def move_to(row, bounds)
          @offset = row
          clamp(bounds)
        end

        def clamp(bounds)
          @offset = offset.clamp(0, bounds.fetch(:max_offset))
          @column = column.clamp(0, bounds.fetch(:max_column))
        end
      end
    end
  end
end
