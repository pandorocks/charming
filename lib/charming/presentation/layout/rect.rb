# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      Rect = Data.define(:x, :y, :width, :height) do
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
