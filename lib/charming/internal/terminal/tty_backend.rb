# frozen_string_literal: true

require "tty-cursor"
require "tty-reader"
require "tty-screen"

module Charming
  module Internal
    module Terminal
      class TTYBackend
        ALT_SCREEN_ON = "\e[?1049h"
        ALT_SCREEN_OFF = "\e[?1049l"
        CTRL_KEY_PATTERN = /\Actrl_(?<key>.+)\z/

        def initialize(input: $stdin, output: $stdout, reader: nil, cursor: TTY::Cursor)
          @input = input
          @output = output
          @reader = reader || TTY::Reader.new(input: input, output: output)
          @cursor = cursor
        end

        def read_event(timeout: nil)
          normalize_keypress(@reader.read_keypress(echo: false, raw: true, nonblock: timeout))
        rescue Errno::EAGAIN, IO::WaitReadable
          nil
        end

        def write_frame(frame)
          @output.write(frame)
          @output.flush
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

        def size
          [TTY::Screen.width, TTY::Screen.height]
        end

        private

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
          return { key: :tab, shift: true } if name == "back_tab"

          { key: name.to_sym, char: printable_char(name) }
        end

        def ctrl_key(name)
          match = name.match(CTRL_KEY_PATTERN)
          { key: match[:key].to_sym, ctrl: true }
        end

        def printable_char(name)
          case name
          when "space" then " "
          when "enter", "return" then "\n"
          when "tab" then "\t"
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
