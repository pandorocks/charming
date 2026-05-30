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
        CTRL_KEY_PATTERN = /\Actrl_(?<key>.+)\z/
        MOUSE_SGR_PATTERN = /\e\[<(\d+);(\d+);(\d+)([HmMhCc]?)(M|m)/
        MOUSE_LEGACY_PATTERN = /\e\[M(.{3})/
        MOUSE_BUTTON_MAP = {
          0 => :left, 1 => :middle, 2 => :right, 3 => :release,
          64 => :scroll_up, 65 => :scroll_down,
          66 => :scroll_up, 67 => :scroll_down
        }.freeze

        def initialize(input: $stdin, output: $stdout, reader: nil, cursor: TTY::Cursor)
          @input = input
          @output = output
          @reader = reader || TTY::Reader.new(input: input, output: output)
          @cursor = cursor
          @resized = false
          @previous_winch_handler = nil
          @mouse_enabled = false
        end

        def read_event(timeout: nil)
          return resize_event if resized?

          raw = @reader.read_keypress(echo: false, raw: true, nonblock: timeout)
          return nil unless raw

          return mouse_event(raw) if mouse_sequence?(raw)

          normalize_keypress(raw)
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
          @output.write(frame)
          @output.flush
        end

        def write_lines(line_changes, **)
          write_control(line_changes.map { |row, line| "\e[#{row};1H\e[2K#{line}" }.join)
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

        def mouse_sequence?(raw)
          return false unless raw.is_a?(String)
          return true if raw.match?(MOUSE_SGR_PATTERN)
          return true if raw.start_with?("\e[M")

          false
        end

        def mouse_event(raw)
          if raw.match?(MOUSE_SGR_PATTERN)
            parse_sgr_mouse(raw)
          else
            parse_legacy_mouse(raw)
          end
        end

        def parse_sgr_mouse(raw)
          match = raw.match(MOUSE_SGR_PATTERN)
          return nil unless match

          # \e[<button>;<col>;<row><mode>M
          button_code = match[1].to_i
          col = match[2].to_i - 1
          row = match[3].to_i - 1
          mode = match[4]

          ctrl = mode == "C"
          alt = raw.include?("\e[38;5;")
          shift = mode == "M"

          MouseEvent.new(button: button_code, x: col, y: row, ctrl: ctrl, alt: alt, shift: shift)
        end

        def parse_legacy_mouse(raw)
          # Legacy format: \e[M + 3 bytes (button, col, row)
          # Each byte is 32 + value (space offset)
          match = raw.match(MOUSE_LEGACY_PATTERN)
          return nil unless match

          bytes = match[1].bytes
          return nil unless bytes.length == 3

          button_code = bytes[0] - 32
          col = bytes[1] - 32
          row = bytes[2] - 32

          MouseEvent.new(button: button_code, x: col, y: row)
        end

        def resized?
          @resized
        end

        def resize_event
          @resized = false
          width, height = size
          ResizeEvent.new(width: width, height: height)
        end

        def normalize_keypress(keypress)
          return nil unless keypress

          key_name = @reader.console.keys[keypress]
          return character_event(keypress) unless key_name

          named_event(key_name)
        end

        def character_event(keypress)
          KeyEvent.new(key: keypress, char: keypress)
        end

        def named_event(key_name)
          normalized = normalize_key_name(key_name)
          KeyEvent.new(
            key: normalized.fetch(:key),
            char: normalized.fetch(:char, nil),
            ctrl: normalized.fetch(:ctrl, false),
            alt: normalized.fetch(:alt, false),
            shift: normalized.fetch(:shift, false)
          )
        end

        def normalize_key_name(key_name)
          name = key_name.to_s
          return ctrl_key(name) if name.match?(CTRL_KEY_PATTERN)
          return {key: :tab, shift: true} if name == "back_tab"

          {key: normalized_key(name), char: printable_char(name)}
        end

        def normalized_key(name)
          return :enter if name == "return"

          name.to_sym
        end

        def ctrl_key(name)
          match = name.match(CTRL_KEY_PATTERN)
          {key: match[:key].to_sym, ctrl: true}
        end

        def printable_char(name)
          case name
          when "space" then " "
          when "enter", "return" then "\n"
          when "tab" then "\t"
          else
            name if name.length == 1 && !name.match?(/[[:cntrl:]]/)
          end
        end

        def write_control(sequence)
          @output.write(sequence)
          @output.flush
        end
      end
    end
  end
end
