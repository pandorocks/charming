# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # Contract for terminal adapters used by Runtime and renderers.
      # Concrete adapters provide input events, terminal dimensions, and output
      # primitives for full or partial frame rendering.
      module Adapter
        def read_event(timeout: nil)
          raise NotImplementedError, "#{self.class} must implement #read_event"
        end

        def size
          raise NotImplementedError, "#{self.class} must implement #size"
        end

        def enter_alt_screen
          raise NotImplementedError, "#{self.class} must implement #enter_alt_screen"
        end

        def leave_alt_screen
          raise NotImplementedError, "#{self.class} must implement #leave_alt_screen"
        end

        def hide_cursor
          raise NotImplementedError, "#{self.class} must implement #hide_cursor"
        end

        def show_cursor
          raise NotImplementedError, "#{self.class} must implement #show_cursor"
        end

        def clear
          raise NotImplementedError, "#{self.class} must implement #clear"
        end

        def move_cursor(row, column)
          raise NotImplementedError, "#{self.class} must implement #move_cursor"
        end

        def write_frame(frame)
          raise NotImplementedError, "#{self.class} must implement #write_frame"
        end

        def write_lines(line_changes, frame: nil)
          raise NotImplementedError, "#{self.class} must implement #write_lines"
        end
      end
    end
  end
end
