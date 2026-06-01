# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      # Rect is an immutable rectangle with a top-left position (x, y) and dimensions
      # (width, height). Layout operations produce new Rect instances rather than mutating
      # existing ones.
      Rect = Data.define(:x, :y, :width, :height) do
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
end
