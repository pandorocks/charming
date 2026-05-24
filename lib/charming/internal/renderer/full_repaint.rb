# frozen_string_literal: true

module Charming
  module Internal
    module Renderer
      class FullRepaint
        def initialize(output)
          @output = output
        end

        def render(frame)
          @output.clear
          @output.move_cursor(1, 1)
          @output.write_frame(frame)
        end
      end
    end
  end
end
