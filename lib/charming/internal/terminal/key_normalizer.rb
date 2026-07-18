# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      # KeyNormalizer turns raw keypress strings (from tty-reader) into normalized
      # KeyEvent objects with a semantic key symbol and the printable character (when
      # applicable). Handles ctrl-modifier naming, special keys (return, tab, space),
      # and the back-tab (Shift+Tab) variant.
      class KeyNormalizer
        # Matches key names like "ctrl_a" → captures "a" so the modifier can be split out.
        CTRL_KEY_PATTERN = /\Actrl_(?<key>.+)\z/

        # *reader* is a TTY::Reader used to look up canonical key names from raw keypresses.
        def initialize(reader)
          @reader = reader
        end

        # Converts a raw *keypress* string into a KeyEvent. Returns nil when *keypress* is nil.
        # Modified CSI sequences (shift/alt/ctrl arrows, function keys) and ESC-prefixed alt
        # chords are decoded first; everything else goes through tty-reader's key table.
        def normalize(keypress)
          return nil unless keypress

          modified = ModifiedKeyParser.parse(keypress)
          return modified if modified

          alt = alt_prefixed_event(keypress)
          return alt if alt

          key_name = @reader.console.keys[keypress]
          return character_event(keypress) unless key_name

          named_event(key_name)
        end

        private

        # Decodes "\e<key>" (Alt held while pressing <key>) by normalizing the inner
        # key and flagging alt. Bare escapes and CSI/SS3 sequences are left alone.
        def alt_prefixed_event(keypress)
          return nil unless keypress.start_with?("\e") && keypress.length >= 2
          return nil if ["[", "O", "\e"].include?(keypress[1])

          inner = normalize(keypress[1..])
          return nil unless inner

          Events::KeyEvent.new(key: inner.key, char: inner.char, ctrl: inner.ctrl, alt: true, shift: inner.shift)
        end

        # Builds a KeyEvent for a raw character keypress (no semantic name was matched).
        def character_event(keypress)
          Events::KeyEvent.new(key: keypress.to_sym, char: keypress)
        end

        # Builds a KeyEvent for a named key, splitting out modifiers and the printable char.
        def named_event(key_name)
          normalized = normalize_key_name(key_name)
          Events::KeyEvent.new(
            key: normalized.fetch(:key),
            char: normalized.fetch(:char, nil),
            ctrl: normalized.fetch(:ctrl, false),
            alt: normalized.fetch(:alt, false),
            shift: normalized.fetch(:shift, false)
          )
        end

        # Splits a key name into its semantic key, printable char, and modifier flags.
        def normalize_key_name(key_name)
          name = key_name.to_s
          return ctrl_key(name) if name.match?(CTRL_KEY_PATTERN)
          return {key: :tab, shift: true} if name == "back_tab"

          {key: normalized_key(name), char: printable_char(name)}
        end

        # Returns the semantic key symbol for *name* (e.g., "return" → :enter).
        def normalized_key(name)
          return :enter if name == "return"

          name.to_sym
        end

        # Returns a key/ctrl-modifier pair for a `ctrl_*` key name.
        def ctrl_key(name)
          match = name.match(CTRL_KEY_PATTERN)
          {key: match[:key].to_sym, ctrl: true}
        end

        # Returns the printable character for *name* (e.g., "space" → " "), or nil when the
        # name has no single-character printable form.
        def printable_char(name)
          case name
          when "space" then " "
          when "enter", "return" then "\n"
          when "tab" then "\t"
          else
            name if name.length == 1 && !name.match?(/[[:cntrl:]]/)
          end
        end
      end
    end
  end
end
