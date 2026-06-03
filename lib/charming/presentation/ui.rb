# frozen_string_literal: true

module Charming
  # UI is a module of layout primitives for composing and positioning ANSI-styled
  # terminal text. It provides functions to join blocks horizontally or vertically,
  # place content on fixed-size canvases, overlay elements, and slice strings that
  # contain ANSI escape sequences while preserving their styling.
  module UI
    module_function

    # Builds a new {Style} instance for chaining color, padding, alignment, and other visual properties.
    def style
      Style.new
    end

    # Horizontally concatenates *blocks* into a single multi-line string, padding each block's
    # rows to match the widest row. A *gap* argument (in spaces) can separate adjacent columns.
    def join_horizontal(*blocks, gap: 0)
      normalized = normalize_blocks(blocks)
      widths = block_widths(normalized)
      separator = " " * gap

      Array.new(block_height(normalized)) do |index|
        horizontal_line(normalized, widths, index).join(separator)
      end.join("\n")
    end

    # Stacks *blocks* vertically separated by one or more blank lines. A *gap* of N inserts N
    # extra newline characters between blocks (1 gap = 1 blank line, 2 gaps = 2 blank lines, etc.).
    def join_vertical(*blocks, gap: 0)
      blocks.join("\n" * (gap + 1))
    end

    # Places *block* onto a blank canvas of *width* × *height* at an offset determined by *top* (row)
    # and *left* (column). Non-:center values are treated as absolute positions. When *background* is
    # given, the assembled frame is wrapped so the theme bg paints the entire canvas — overlay content
    # with its own bg overrides per-cell; resets re-apply the canvas bg.
    def place(block, width:, height:, top: 0, left: 0, background: nil)
      Canvas.new(width, height).place(block, top: top, left: left, background: background)
    end

    # Draws *overlay* on top of a base at the specified *top* (row) and *left* (column) coordinates,
    # defaulting to center in both directions. ANSI styling on the base content is preserved underneath.
    def overlay(base, overlay, top: :center, left: :center)
      Canvas.parse(base).overlay(overlay, top: top, left: left).to_s
    end

    # Centers a *block* within a canvas of the given *width* and *height*, then returns the result.
    def center(block, width:, height:, background: nil)
      place(block, width: width, height: height, top: :center, left: :center, background: background)
    end

    # Returns a visible-slice of *line* starting at *start_column* spanning *width* characters, preserving any
    # ANSI escape sequences that were active at the start of the slice. Non-positive widths return `""`.
    def visible_slice(line, start_column, width)
      ANSISlicer.slice(line, start_column, width)
    end

    # Normalizes an array of mixed objects into arrays of lines by calling `#to_s` on each element.
    def normalize_blocks(blocks)
      blocks.map { |block| block.to_s.lines(chomp: true) }
    end

    # Measures the displayed (visual) width of each normalised block, returning an array of integer widths.
    def block_widths(blocks)
      blocks.map { |lines| lines.map { |line| Width.measure(line) }.max || 0 }
    end

    # Returns the maximum visual character width across all *lines*, accounting for multi-column characters
    # (e.g., full-width CJK glyphs) and invisible ANSI escape sequences.
    def block_width(lines)
      lines.map { |line| Width.measure(line) }.max || 0
    end

    # Returns the height in rows of each normalised block, taking the maximum across all blocks.
    def block_height(blocks)
      blocks.map(&:length).max || 0
    end

    # Builds a single horizontal row by concatenating one line from each *block* at index *index*, padding
    # every segment to its corresponding *width* in spaces. Returns the assembled array of padded segments.
    def horizontal_line(blocks, widths, index)
      blocks.each_with_index.map do |lines, block_index|
        line = lines[index] || ""
        line + (" " * (widths[block_index] - Width.measure(line)))
      end
    end
  end
end
