# frozen_string_literal: true

module Charming
  module Internal
    module Terminal
      class KeyNormalizer
        CTRL_KEY_PATTERN = /\Actrl_(?<key>.+)\z/

        def initialize(reader)
          @reader = reader
        end

        def normalize(keypress)
          return nil unless keypress

          key_name = @reader.console.keys[keypress]
          return character_event(keypress) unless key_name

          named_event(key_name)
        end

        private

        def character_event(keypress)
          Events::KeyEvent.new(key: keypress.to_sym, char: keypress)
        end

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
      end
    end
  end
end
