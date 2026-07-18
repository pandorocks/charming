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

    # Builds a color that resolves to *light* or *dark* at render time based on
    # the terminal background. Usable anywhere a color is accepted.
    def adaptive(light:, dark:)
      AdaptiveColor.new(light: light, dark: dark)
    end

    # Horizontally concatenates *blocks* into a single multi-line string, padding each block's
    # rows to match the widest row. A *gap* argument (in spaces) can separate adjacent columns.
    # *align* positions shorter blocks along the cross axis: `:top` (default), `:center`,
    # `:bottom`, or a fraction between 0.0 and 1.0.
    def join_horizontal(*blocks, gap: 0, align: :top)
      normalized = normalize_blocks(blocks)
      height = block_height(normalized)
      aligned = normalized.map { |lines| offset_rows(lines, height, align) }
      widths = block_widths(normalized)
      separator = " " * gap

      Array.new(height) do |index|
        horizontal_line(aligned, widths, index).join(separator)
      end.join("\n")
    end

    # Stacks *blocks* vertically separated by one or more blank lines, padding narrower
    # blocks' lines to the widest block. A *gap* of N inserts N extra newline characters
    # between blocks. *align* positions narrower lines along the cross axis: `:left`
    # (default), `:center`, `:right`, or a fraction between 0.0 and 1.0.
    def join_vertical(*blocks, gap: 0, align: :left)
      normalized = normalize_blocks(blocks)
      width = block_widths(normalized).max || 0

      normalized.map { |lines| lines.map { |line| align_to(line, width, align) }.join("\n") }
        .join("\n" * (gap + 1))
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
      blocks.map { |lines| Width.widest(lines) }
    end

    # Returns the maximum visual character width across all *lines*, accounting for multi-column characters
    # (e.g., full-width CJK glyphs) and invisible ANSI escape sequences.
    def block_width(lines)
      Width.widest(lines)
    end

    # Returns the height in rows of each normalised block, taking the maximum across all blocks.
    def block_height(blocks)
      blocks.map(&:length).max || 0
    end

    # Builds a single horizontal row by concatenating one line from each *block* at index *index*, padding
    # every segment to its corresponding *width* in spaces. Returns the assembled array of padded segments.
    def horizontal_line(blocks, widths, index)
      blocks.each_with_index.map do |lines, block_index|
        Width.pad_to(lines[index] || "", widths[block_index])
      end
    end

    # Prepends blank rows to *lines* so the block sits at the cross-axis position
    # given by *align* within *height* total rows.
    def offset_rows(lines, height, align)
      Array.new(cross_offset(align, height - lines.length), "") + lines
    end

    # Pads *line* to *width*, splitting the slack per the cross-axis *align* position.
    def align_to(line, width, align)
      slack = width - Width.measure(line)
      return line if slack <= 0

      leading = cross_offset(align, slack)
      (" " * leading) + line + (" " * (slack - leading))
    end

    # Resolves an alignment (`:top`/`:left` → 0.0, `:center` → 0.5, `:bottom`/`:right` → 1.0,
    # or a fraction) into a whole-cell offset within *slack* spare cells.
    CROSS_POSITIONS = {top: 0.0, left: 0.0, center: 0.5, middle: 0.5, bottom: 1.0, right: 1.0}.freeze

    def cross_offset(align, slack)
      return 0 if slack <= 0

      position = CROSS_POSITIONS.fetch(align, align)
      (slack * position.to_f).round.clamp(0, slack)
    end
  end
end
