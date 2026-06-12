# frozen_string_literal: true

require "unicode/display_width"

module Charming
  module UI
    # Width is a namespace for measuring and normalising the visual width of strings that may contain
    # ANSI escape sequences. It delegates to `Unicode::DisplayWidth` while automatically stripping
    # formatting codes so layout primitives can calculate exact character positions.
    module Width
      # Matches OSC sequences (e.g. OSC 8 hyperlinks, terminated by BEL or ST),
      # CSI sequences (SGR colors/attributes, cursor movement), and single-character
      # Fe escapes. The OSC branch must come first and the Fe class must exclude
      # "[" and "]", or "\e]" would match as a bare Fe escape and leave the OSC
      # payload counted as visible text.
      ANSI_PATTERN = /\e(?:\][^\a]*?(?:\a|\e\\)|\[[0-9;?]*[@-~]|[@-Z\\^_])/

      module_function

      def measure(value)
        Unicode::DisplayWidth.of(strip_ansi(value.to_s))
      end

      def strip_ansi(value)
        value.to_s.gsub(ANSI_PATTERN, "")
      end
    end
  end
end
