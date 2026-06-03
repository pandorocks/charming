# frozen_string_literal: true

module Charming
  module Layout
    # Rect is an immutable rectangle with a top-left position (x, y) and dimensions
    # (width, height). Layout operations produce new Rect instances rather than mutating
    # existing ones.
    Rect = Data.define(:x, :y, :width, :height) do
      # Returns true when the zero-based cell coordinate falls within this rectangle.
      def cover?(point_x, point_y)
        point_x >= x && point_x < x + width && point_y >= y && point_y < y + height
      end

      # Returns a new Rect inset by *top*/*right*/*bottom*/*left* cells. The result is
      # clamped to a minimum width/height of 0.
      def inset(top: 0, right: 0, bottom: 0, left: 0)
        Rect.new(
          x: x + left,
          y: y + top,
          width: [width - left - right, 0].max,
          height: [height - top - bottom, 0].max
        )
      end
    end
  end
end
