# frozen_string_literal: true

require "tty-cursor"
require "tty-reader"
require "tty-screen"

module Charming
  module Internal
    module Terminal
      # TTYBackend is the production terminal backend. It reads key and mouse events from
      # a TTY::Reader, normalizes them via KeyNormalizer and MouseParser, and writes output
      # frames using TTY::Cursor and TTY::Screen. It also installs SIGWINCH and SIGINFO
      # handlers so the runtime can react to terminal resize and focus changes.
      class TTYBackend
        include Adapter

        # Escape sequences for entering/leaving the alternate screen buffer.
        ALT_SCREEN_ON = "\e[?1049h"
        ALT_SCREEN_OFF = "\e[?1049l"

        # Escape sequences for disabling/enabling automatic line wrapping during frame writes.
        AUTO_WRAP_OFF = "\e[?7l"
        AUTO_WRAP_ON = "\e[?7h"

        # *input* and *output* default to `$stdin`/`$stdout` for normal terminal use;
        # tests can inject IO objects. *reader* is a TTY::Reader instance (created from
        # *input*/*output* when nil). *cursor* is the TTY::Cursor class used for cursor control.
        def initialize(input: $stdin, output: $stdout, reader: nil, cursor: TTY::Cursor)
          @input = input
          @output = output
          @reader = reader || TTY::Reader.new(input: input, output: output)
          @cursor = cursor
          @key_normalizer = KeyNormalizer.new(@reader)
          @resized = false
          @previous_winch_handler = nil
          @mouse_enabled = false
        end

        # Reads the next event. If a SIGWINCH was received, returns a ResizeEvent with the
        # current terminal dimensions. Mouse escape sequences are parsed by MouseParser;
        # other input is normalized via KeyNormalizer. Returns nil on timeout.
        def read_event(timeout: nil)
          return resize_event if resized?

          raw = @reader.read_keypress(echo: false, raw: true, nonblock: timeout)
          return nil unless raw
          return MouseParser.parse(raw) if MouseParser.sequence?(raw)

          @key_normalizer.normalize(raw)
        rescue Errno::EAGAIN, IO::WaitReadable
          nil
        end

        # Installs a SIGWINCH handler that sets the internal `@resized` flag, returning
        # the previous handler so it can be restored on teardown.
        def install_resize_handler
          @previous_winch_handler = Signal.trap("WINCH") { @resized = true }
        end

        # Installs a SIGINFO handler that marks the terminal as having received focus.
        # SIGINFO is sent by some terminals (notably macOS Terminal.app) on focus changes.
        def install_focus_handler
          # Terminal focus change: some terminals send a special sequence
          # when focus changes. We use this to throttle rendering.
          @previous_focus_handler = Signal.trap("INFO") { @focused = true }
        end

        # Restores the previous SIGINFO handler.
        def restore_focus_handler
          Signal.trap("INFO", @previous_focus_handler) if @previous_focus_handler
          @previous_focus_handler = nil
        end

        # Restores the previous SIGWINCH handler captured by `install_resize_handler`.
        def restore_resize_handler
          Signal.trap("WINCH", @previous_winch_handler) if @previous_winch_handler
          @previous_winch_handler = nil
        end

        # Emits the ANSI sequences that enable terminal mouse reporting (press, motion, SGR).
        # Idempotent: skipped when mouse tracking is already enabled.
        def enable_mouse_tracking
          return if @mouse_enabled

          write_control("\e[?1000h")
          write_control("\e[?1002h")
          write_control("\e[?1006h")
          @mouse_enabled = true
        end

        # Emits the ANSI sequences that disable terminal mouse reporting. Idempotent.
        def disable_mouse_tracking
          return unless @mouse_enabled

          write_control("\e[?1000l")
          write_control("\e[?1002l")
          write_control("\e[?1003l")
          write_control("\e[?1006l")
          @mouse_enabled = false
        end

        # Returns whether mouse tracking is currently enabled on this backend.
        def mouse_enabled?
          @mouse_enabled
        end

        # Manually flags the backend as resized (used by tests or external integrations).
        def notify_resize
          @resized = true
        end

        # Writes a full multi-line *frame* to the terminal, disabling auto-wrap during
        # the write so overlong lines don't disturb the screen layout.
        def write_frame(frame)
          without_auto_wrap do
            write_positioned_lines(frame.to_s.lines(chomp: true))
          end
        end

        # Writes a partial frame composed of [row, line] tuples (1-based rows).
        def write_lines(line_changes, **)
          without_auto_wrap do
            write_control(line_changes.map { |row, line| positioned_line(row, line) }.join)
          end
        end

        # Enters the alternate screen buffer.
        def enter_alt_screen
          write_control(ALT_SCREEN_ON)
        end

        # Leaves the alternate screen buffer.
        def leave_alt_screen
          write_control(ALT_SCREEN_OFF)
        end

        # Shows the terminal cursor.
        def show_cursor
          write_control(@cursor.show)
        end

        # Hides the terminal cursor.
        def hide_cursor
          write_control(@cursor.hide)
        end

        # Clears the terminal screen and moves the cursor to (1, 1).
        def clear
          write_control(@cursor.clear_screen)
        end

        # Moves the terminal cursor to the given 1-based (row, column).
        def move_cursor(row, column)
          write_control(@cursor.move_to(column - 1, row - 1))
        end

        # Returns the current terminal dimensions as [width, height] via TTY::Screen.
        def size = [TTY::Screen.width, TTY::Screen.height]

        private

        # True when the SIGWINCH flag has been set since the last read_event.
        def resized?
          @resized
        end

        # Consumes the resize flag, measures the current terminal, and returns a ResizeEvent.
        def resize_event
          @resized = false
          width, height = size
          Events::ResizeEvent.new(width: width, height: height)
        end

        # Writes a raw escape *sequence* to the output stream and flushes.
        def write_control(sequence)
          @output.write(sequence)
          @output.flush
        end

        # Writes *lines* one row at a time, with each line preceded by an ANSI cursor
        # position and a clear-to-end-of-line sequence.
        def write_positioned_lines(lines)
          write_control(lines.each_with_index.map { |line, index| positioned_line(index + 1, line) }.join)
        end

        # Resets SGR before and after each row so partial repaint rows cannot inherit
        # colors/backgrounds from the previous physical terminal line.
        def positioned_line(row, line)
          "\e[0m\e[#{row};1H\e[2K#{line}\e[0m"
        end

        # Disables auto-wrap, yields, then re-enables it and flushes the output.
        def without_auto_wrap
          @output.write(AUTO_WRAP_OFF)
          yield
        ensure
          @output.write(AUTO_WRAP_ON)
          @output.flush
        end
      end
    end
  end
end
