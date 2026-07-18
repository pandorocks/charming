# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # MouseParser parses raw terminal escape sequences into MouseEvent objects.
      # Supports both modern SGR sequences (the most common, used by current terminals)
      # and the older 3-byte legacy sequences. Both encodings pack modifiers and motion
      # into the button code: bit 2 shift, bit 3 alt/meta, bit 4 ctrl, bit 5 motion.
      # SGR signals release with a final "m" instead of "M". The public API is class
      # methods; no instance state is required.
      class MouseParser
        # Matches an SGR-encoded mouse sequence: "\e[<button;col;row" + "M" (press) or "m" (release).
        SGR_PATTERN = /\e\[<(\d+);(\d+);(\d+)(M|m)/

        # Matches the legacy 3-byte mouse sequence: "\e[M" followed by 3 bytes.
        LEGACY_PATTERN = /\e\[M(.{3})/

        # Button-code bits for modifier keys and motion (shared by SGR and legacy).
        SHIFT_BIT = 4
        ALT_BIT = 8
        CTRL_BIT = 16
        MOTION_BIT = 32
        FLAG_BITS = SHIFT_BIT | ALT_BIT | CTRL_BIT | MOTION_BIT

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

        # Parses an SGR-format mouse sequence: button code with flag bits, 1-based
        # (col, row), and the press/release final byte.
        def self.parse_sgr(raw)
          match = raw.match(SGR_PATTERN)
          return nil unless match

          build_event(match[1].to_i, match[2].to_i - 1, match[3].to_i - 1, release: match[4] == "m")
        end

        # Parses a legacy 3-byte mouse sequence. Each of the 3 bytes has 32 subtracted
        # to recover the (button, col, row) values.
        def self.parse_legacy(raw)
          match = raw.match(LEGACY_PATTERN)
          return nil unless match

          bytes = match[1].bytes
          return nil unless bytes.length == 3

          build_event(bytes[0] - 32, bytes[1] - 32, bytes[2] - 32, release: false)
        end

        # Builds a MouseEvent from a raw button *code*, splitting out the modifier
        # and motion flag bits so `button` carries only the button/wheel identity.
        def self.build_event(code, x, y, release:)
          Events::MouseEvent.new(
            button: code & ~FLAG_BITS,
            x: x,
            y: y,
            shift: code.anybits?(SHIFT_BIT),
            alt: code.anybits?(ALT_BIT),
            ctrl: code.anybits?(CTRL_BIT),
            motion: code.anybits?(MOTION_BIT),
            release: release
          )
        end

        private_class_method :build_event
      end
    end
  end
end
