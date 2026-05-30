# frozen_string_literal: true

require "unicode/display_width"

module Charming
   module UI
    # Width is a namespace for measuring and normalising the visual width of strings that may contain
      # ANSI escape sequences. It delegates to `Unicode::DisplayWidth` while automatically stripping
      # formatting codes so layout primitives can calculate exact character positions.
     module Width
      ANSI_PATTERN = /\e\[[0-9;]*m/

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
