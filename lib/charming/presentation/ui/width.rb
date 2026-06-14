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

      # A grapheme cluster containing either codepoint renders as a single emoji
      # (double-width) cell in a terminal: U+200D ZWJ joins a multi-glyph emoji
      # sequence, and U+FE0F (VS16) requests emoji presentation. The
      # unicode-display_width tables disagree with terminals here — e.g. "⚔️"
      # measures 1 and "🧙‍♂️" measures 3 — so we pin such clusters to 2.
      EMOJI_PRESENTATION = /[\u200D\uFE0F]/

      # Onig's \X matches one extended grapheme cluster, keeping multi-codepoint
      # emoji together so each is measured (and later sliced) as one unit.
      GRAPHEME = /\X/

      module_function

      def measure(value)
        stripped = strip_ansi(value.to_s)
        return Unicode::DisplayWidth.of(stripped) unless stripped.match?(EMOJI_PRESENTATION)

        stripped.scan(GRAPHEME).sum { |cluster| cluster_width(cluster) }
      end

      def cluster_width(cluster)
        return 2 if cluster.match?(EMOJI_PRESENTATION)

        Unicode::DisplayWidth.of(cluster)
      end

      def strip_ansi(value)
        value.to_s.gsub(ANSI_PATTERN, "")
      end
    end
  end
end
