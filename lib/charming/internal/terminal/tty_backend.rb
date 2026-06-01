# frozen_string_literal: true

require "tty-cursor"
require "tty-reader"
require "tty-screen"

module Charming
  module Internal
    module Terminal
      class TTYBackend
        include Adapter

        ALT_SCREEN_ON = "\e[?1049h"
        ALT_SCREEN_OFF = "\e[?1049l"
        AUTO_WRAP_OFF = "\e[?7l"
        AUTO_WRAP_ON = "\e[?7h"

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

        def read_event(timeout: nil)
          return resize_event if resized?

          raw = @reader.read_keypress(echo: false, raw: true, nonblock: timeout)
          return nil unless raw
          return MouseParser.parse(raw) if MouseParser.sequence?(raw)

          @key_normalizer.normalize(raw)
        rescue Errno::EAGAIN, IO::WaitReadable
          nil
        end

        def install_resize_handler
          @previous_winch_handler = Signal.trap("WINCH") { @resized = true }
        end

        def install_focus_handler
          # Terminal focus change: some terminals send a special sequence
          # when focus changes. We use this to throttle rendering.
          @previous_focus_handler = Signal.trap("INFO") { @focused = true }
        end

        def restore_focus_handler
          Signal.trap("INFO", @previous_focus_handler) if @previous_focus_handler
          @previous_focus_handler = nil
        end

        def restore_resize_handler
          Signal.trap("WINCH", @previous_winch_handler) if @previous_winch_handler
          @previous_winch_handler = nil
        end

        def enable_mouse_tracking
          return if @mouse_enabled

          write_control("\e[?1000h")
          write_control("\e[?1002h")
          write_control("\e[?1006h")
          @mouse_enabled = true
        end

        def disable_mouse_tracking
          return unless @mouse_enabled

          write_control("\e[?1000l")
          write_control("\e[?1002l")
          write_control("\e[?1003l")
          write_control("\e[?1006l")
          @mouse_enabled = false
        end

        def mouse_enabled?
          @mouse_enabled
        end

        def notify_resize
          @resized = true
        end

        def write_frame(frame)
          without_auto_wrap do
            write_positioned_lines(frame.to_s.lines(chomp: true))
          end
        end

        def write_lines(line_changes, **)
          without_auto_wrap do
            write_control(line_changes.map { |row, line| "\e[#{row};1H\e[2K#{line}" }.join)
          end
        end

        def enter_alt_screen
          write_control(ALT_SCREEN_ON)
        end

        def leave_alt_screen
          write_control(ALT_SCREEN_OFF)
        end

        def show_cursor
          write_control(@cursor.show)
        end

        def hide_cursor
          write_control(@cursor.hide)
        end

        def clear
          write_control(@cursor.clear_screen)
        end

        def move_cursor(row, column)
          write_control(@cursor.move_to(column - 1, row - 1))
        end

        def size = [TTY::Screen.width, TTY::Screen.height]

        private

        def resized?
          @resized
        end

        def resize_event
          @resized = false
          width, height = size
          Events::ResizeEvent.new(width: width, height: height)
        end

        def write_control(sequence)
          @output.write(sequence)
          @output.flush
        end

        def write_positioned_lines(lines)
          write_control(lines.each_with_index.map { |line, index| "\e[#{index + 1};1H\e[2K#{line}" }.join)
        end

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
