# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      class MemoryBackend
        attr_reader :frames, :operations

        def initialize(events: [], width: 80, height: 24)
          @events = events.dup
          @width = width
          @height = height
          @frames = []
          @operations = []
        end

        def read_event(timeout: nil)
          @operations << [:read_event, timeout]
          @events.shift
        end

        def write_frame(frame)
          @frames << frame
          @operations << [:write_frame, frame]
        end

        def enter_alt_screen
          @operations << :enter_alt_screen
        end

        def leave_alt_screen
          @operations << :leave_alt_screen
        end

        def show_cursor
          @operations << :show_cursor
        end

        def hide_cursor
          @operations << :hide_cursor
        end

        def clear
          @operations << :clear
        end

        def move_cursor(row, column)
          @operations << [:move_cursor, row, column]
        end

        def size
          [@width, @height]
        end
      end
    end
  end
end
