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

        # True when at least one input event is immediately available to read without blocking.
        # The runtime uses this to drain held-key auto-repeat without stalling on the final,
        # empty read. Defaults to false so a backend that can't answer simply opts out of
        # coalescing (the runtime then dispatches each event individually).
        def input_pending?
          false
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

        # Writes an out-of-band escape sequence (image transmission, clipboard write, notification,
        # window title) straight to the terminal, bypassing the line-based frame pipeline. *sequence*
        # responds to `payload` (the escape-sequence string). Defaults to a no-op so backends opt in.
        def write_escape(sequence)
        end
      end
    end
  end
end
