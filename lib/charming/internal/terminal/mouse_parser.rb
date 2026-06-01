# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      class MouseParser
        SGR_PATTERN = /\e\[<(\d+);(\d+);(\d+)([HmMhCc]?)(M|m)/
        LEGACY_PATTERN = /\e\[M(.{3})/
        BUTTON_MAP = {
          0 => :left, 1 => :middle, 2 => :right, 3 => :release,
          64 => :scroll_up, 65 => :scroll_down,
          66 => :scroll_up, 67 => :scroll_down
        }.freeze

        def self.sequence?(raw)
          return false unless raw.is_a?(String)
          return true if raw.match?(SGR_PATTERN)
          return true if raw.start_with?("\e[M")

          false
        end

        def self.parse(raw)
          return nil unless raw.is_a?(String)
          return parse_sgr(raw) if raw.match?(SGR_PATTERN)
          return parse_legacy(raw) if raw.start_with?("\e[M")

          nil
        end

        def self.parse_sgr(raw)
          match = raw.match(SGR_PATTERN)
          return nil unless match

          button_code = match[1].to_i
          col = match[2].to_i - 1
          row = match[3].to_i - 1
          mode = match[4]

          ctrl = mode == "C"
          alt = raw.include?("\e[38;5;")
          shift = mode == "M"

          Events::MouseEvent.new(button: button_code, x: col, y: row, ctrl: ctrl, alt: alt, shift: shift)
        end

        def self.parse_legacy(raw)
          match = raw.match(LEGACY_PATTERN)
          return nil unless match

          bytes = match[1].bytes
          return nil unless bytes.length == 3

          button_code = bytes[0] - 32
          col = bytes[1] - 32
          row = bytes[2] - 32

          Events::MouseEvent.new(button: button_code, x: col, y: row)
        end
      end
    end
  end
end
