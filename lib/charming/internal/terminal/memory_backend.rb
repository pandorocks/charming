# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # MemoryBackend is an in-memory implementation of the terminal Adapter used by
      # RSpec specs. It serves events from a fixed `events:` list and records every
      # output operation in `frames` (rendered output) and `operations` (every method
      # call with its arguments), so tests can assert against observed output.
      class MemoryBackend
        include Adapter

        # The array of rendered frame strings (one per `write_frame` or `write_lines` call).
        attr_reader :frames

        # The array of recorded operation tuples: [:method_name, *args].
        attr_reader :operations

        # *events* is the queue of pre-seeded events to return from `read_event`.
        # *width*/*height* set the initial terminal dimensions reported by `size`.
        def initialize(events: [], width: 80, height: 24)
          @events = events.dup
          @width = width
          @height = height
          @frames = []
          @operations = []
          @mouse_enabled = false
        end

        # Pops the next pre-seeded event from the queue. Returns nil when the queue is empty.
        def read_event(timeout: nil)
          @operations << [:read_event, timeout]
          @events.shift
        end

        # Stores *frame* as the current frame and appends it to `frames`.
        def write_frame(frame)
          @current_frame = frame
          @frames << frame
          @operations << [:write_frame, frame]
        end

        # Applies the [row, line] *line_changes* to the current frame, then stores and
        # records the result. The full frame is taken from the optional *frame:* argument
        # (when provided) or built by overlaying the changes on the previous frame.
        def write_lines(line_changes, frame: nil)
          @current_frame = frame || apply_line_changes(line_changes)
          @frames << @current_frame
          @operations << [:write_lines, line_changes]
        end

        # Records an enter-alt-screen operation.
        def enter_alt_screen
          @operations << :enter_alt_screen
        end

        # Records a leave-alt-screen operation.
        def leave_alt_screen
          @operations << :leave_alt_screen
        end

        # Records a show-cursor operation.
        def show_cursor
          @operations << :show_cursor
        end

        # Records a hide-cursor operation.
        def hide_cursor
          @operations << :hide_cursor
        end

        # Records a clear-screen operation.
        def clear
          @operations << :clear
        end

        # Records a move-cursor operation at the given (row, column) (1-based).
        def move_cursor(row, column)
          @operations << [:move_cursor, row, column]
        end

        # Returns the configured terminal dimensions as [width, height].
        def size
          [@width, @height]
        end

        # Marks the backend as having mouse tracking enabled and records the operation.
        def enable_mouse_tracking
          @mouse_enabled = true
          @operations << :enable_mouse_tracking
        end

        # Marks the backend as having mouse tracking disabled and records the operation.
        def disable_mouse_tracking
          @mouse_enabled = false
          @operations << :disable_mouse_tracking
        end

        # Returns whether mouse tracking is currently enabled.
        def mouse_enabled?
          @mouse_enabled
        end

        private

        # Overlays each [row, line] from *line_changes* onto a copy of the current frame
        # (1-based row indexing). Used when `write_lines` is called without a *frame:* argument.
        def apply_line_changes(line_changes)
          lines = @current_frame.to_s.lines(chomp: true)
          line_changes.each do |row, line|
            lines[row - 1] = line
          end
          lines.join("\n")
        end
      end
    end
  end
end
