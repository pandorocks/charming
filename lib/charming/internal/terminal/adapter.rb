# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # Adapter defines the duck-typed interface that terminal backends must implement.
      # Concrete adapters (`TTYBackend`, `MemoryBackend`) mix this module in and provide
      # the actual implementations; the methods below raise NotImplementedError to make
      # missing implementations fail loudly.
      #
      # Input methods:
      # - `read_event(timeout:)` returns the next event (KeyEvent, MouseEvent, or nil on timeout)
      #
      # Output methods:
      # - `size` returns the [width, height] of the terminal
      # - `enter_alt_screen` / `leave_alt_screen` switch to/from the alternate screen buffer
      # - `hide_cursor` / `show_cursor` toggle the cursor
      # - `clear` clears the screen
      # - `move_cursor(row, column)` positions the cursor (1-based)
      # - `write_frame(frame)` writes a full multi-line frame string
      # - `write_lines(line_changes, frame: nil)` writes a partial frame of [row, line] changes
      module Adapter
        # Reads the next event from the backend. Returns nil when no event is available
        # within *timeout* seconds. Must be implemented by the including class.
        def read_event(timeout: nil)
          raise NotImplementedError, "#{self.class} must implement #read_event"
        end

        # Returns the current terminal dimensions as [width, height] in cells.
        def size
          raise NotImplementedError, "#{self.class} must implement #size"
        end

        # Switches the terminal into the alternate screen buffer (used to keep the host
        # terminal scrollback untouched while a TUI app is running).
        def enter_alt_screen
          raise NotImplementedError, "#{self.class} must implement #enter_alt_screen"
        end

        # Returns the terminal to the primary screen buffer (paired with `enter_alt_screen`).
        def leave_alt_screen
          raise NotImplementedError, "#{self.class} must implement #leave_alt_screen"
        end

        # Hides the terminal cursor.
        def hide_cursor
          raise NotImplementedError, "#{self.class} must implement #hide_cursor"
        end

        # Shows the terminal cursor.
        def show_cursor
          raise NotImplementedError, "#{self.class} must implement #show_cursor"
        end

        # Clears the entire screen and homes the cursor.
        def clear
          raise NotImplementedError, "#{self.class} must implement #clear"
        end

        # Moves the cursor to the given 1-based (row, column) position.
        def move_cursor(row, column)
          raise NotImplementedError, "#{self.class} must implement #move_cursor"
        end

        # Writes a full multi-line frame string to the terminal in one operation.
        def write_frame(frame)
          raise NotImplementedError, "#{self.class} must implement #write_frame"
        end

        # Writes a partial frame composed of [row, line] tuples. Optional *frame:* is the
        # full frame string for backends that want to track it (e.g., the MemoryBackend).
        def write_lines(line_changes, frame: nil)
          raise NotImplementedError, "#{self.class} must implement #write_lines"
        end
      end
    end
  end
end
