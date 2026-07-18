# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # ModifiedKeyParser decodes xterm CSI sequences that carry a modifier
      # parameter — "\e[1;2A" (shift+up), "\e[3;5~" (ctrl+delete) — which
      # tty-reader's key table does not cover. The modifier parameter encodes
      # 1 + (1 shift | 2 alt | 4 ctrl | 8 meta); meta is treated as alt.
      class ModifiedKeyParser
        # "\e[1;<mod><final>" — arrows, home/end, and the SS3-style F1-F4 finals.
        LETTER_PATTERN = /\A\e\[1;(\d+)([A-DFHPQRS])\z/

        # "\e[<code>;<mod>~" — insert/delete, page keys, home/end, F5-F12.
        TILDE_PATTERN = /\A\e\[(\d+);(\d+)~\z/

        LETTER_KEYS = {
          "A" => :up, "B" => :down, "C" => :right, "D" => :left,
          "F" => :end, "H" => :home,
          "P" => :f1, "Q" => :f2, "R" => :f3, "S" => :f4
        }.freeze

        TILDE_KEYS = {
          1 => :home, 2 => :insert, 3 => :delete, 4 => :end,
          5 => :page_up, 6 => :page_down, 7 => :home, 8 => :end,
          15 => :f5, 17 => :f6, 18 => :f7, 19 => :f8,
          20 => :f9, 21 => :f10, 23 => :f11, 24 => :f12
        }.freeze

        SHIFT_BIT = 1
        ALT_BIT = 2
        CTRL_BIT = 4
        META_BIT = 8

        # Parses *raw* into a KeyEvent with modifier flags, or nil when it is not
        # a modified CSI sequence.
        def self.parse(raw)
          return nil unless raw.is_a?(String)

          if (match = raw.match(LETTER_PATTERN))
            build_event(LETTER_KEYS[match[2]], match[1].to_i)
          elsif (match = raw.match(TILDE_PATTERN))
            build_event(TILDE_KEYS[match[1].to_i], match[2].to_i)
          end
        end

        def self.build_event(key, modifier_param)
          return nil unless key

          bits = modifier_param - 1
          Events::KeyEvent.new(
            key: key,
            shift: bits.anybits?(SHIFT_BIT),
            alt: bits.anybits?(ALT_BIT | META_BIT),
            ctrl: bits.anybits?(CTRL_BIT)
          )
        end

        private_class_method :build_event
      end
    end
  end
end
