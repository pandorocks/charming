# frozen_string_literal: true

module Charming
  module Internal
    module Renderer
      # FullRepaint clears the screen and rewrites the entire frame on every render. It is
      # used as the initial render path by Differential and as a fallback for backends that
      # don't support partial line writes.
      class FullRepaint
        # *output* is the terminal backend (must support `clear`, `move_cursor`, and
        # `write_frame` per the Adapter contract).
        def initialize(output)
          @output = output
        end

        # Clears the screen, homes the cursor, and writes the entire *frame* string.
        def render(frame)
          @output.clear
          @output.move_cursor(1, 1)
          @output.write_frame(frame)
        end
      end
    end
  end
end
