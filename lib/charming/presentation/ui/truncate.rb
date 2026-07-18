# frozen_string_literal: true

module Charming
  module UI
    # Truncate cuts ANSI-styled text down to a display width, marking the cut
    # with a trailing ellipsis. Styling active at the cut is preserved and
    # terminated, and multi-column glyphs are never split (matching ANSISlicer).
    module Truncate
      ELLIPSIS = "…"

      module_function

      # Truncates each line of *text* to *width* display columns, appending
      # *ellipsis* to lines that overflow. Lines that fit are returned unchanged.
      def tail(text, width, ellipsis: ELLIPSIS)
        text.to_s.lines(chomp: true).map { |line| tail_line(line, width, ellipsis) }.join("\n")
      end

      def tail_line(line, width, ellipsis)
        return line if Width.measure(line) <= width

        ellipsis_width = Width.measure(ellipsis)
        return ANSISlicer.slice(line, 0, width) if ellipsis_width >= width

        ANSISlicer.slice(line, 0, width - ellipsis_width) + ellipsis
      end
    end
  end
end
