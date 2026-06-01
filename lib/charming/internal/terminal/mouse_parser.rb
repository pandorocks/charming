# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # MouseParser parses raw terminal escape sequences into MouseEvent objects.
      # Supports both modern SGR sequences (the most common, used by current terminals)
      # and the older 3-byte legacy sequences. The public API is class methods; no
      # instance state is required.
      class MouseParser
        # Matches an SGR-encoded mouse sequence: "\e[<button;col;row[mode]M"
        SGR_PATTERN = /\e\[<(\d+);(\d+);(\d+)([HmMhCc]?)(M|m)/

        # Matches the legacy 3-byte mouse sequence: "\e[M" followed by 3 bytes.
        LEGACY_PATTERN = /\e\[M(.{3})/

        # Maps raw button codes to semantic symbols used by MouseEvent#button_name.
        BUTTON_MAP = {
          0 => :left, 1 => :middle, 2 => :right, 3 => :release,
          64 => :scroll_up, 65 => :scroll_down,
          66 => :scroll_up, 67 => :scroll_down
        }.freeze

        # Returns true when *raw* looks like a recognizable mouse sequence (SGR or legacy).
        # Lets the TTYBackend short-circuit and dispatch to MouseParser without allocation.
        def self.sequence?(raw)
          return false unless raw.is_a?(String)
          return true if raw.match?(SGR_PATTERN)
          return true if raw.start_with?("\e[M")

          false
        end

        # Parses *raw* into a MouseEvent, or returns nil when the string is not a mouse
        # sequence or cannot be decoded.
        def self.parse(raw)
          return nil unless raw.is_a?(String)
          return parse_sgr(raw) if raw.match?(SGR_PATTERN)
          return parse_legacy(raw) if raw.start_with?("\e[M")

          nil
        end

        # Parses an SGR-format mouse sequence. Decodes button code, 1-based (col, row),
        # the modifier "C" (ctrl) and "M" (shift) suffix, and the highlight alt (256-color)
        # sequence as a heuristic for the alt modifier.
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

        # Parses a legacy 3-byte mouse sequence. Each of the 3 bytes has 32 subtracted
        # to recover the (button, col, row) values.
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
