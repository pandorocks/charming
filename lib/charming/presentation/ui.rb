# frozen_string_literal: true

module Charming
  module Presentation
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

      # Centers a *block* within a canvas of the given *width* and *height*, then returns the result.
      def center(block, width:, height:, background: nil)
        place(block, width: width, height: height, top: :center, left: :center, background: background)
      end

      # Draws *overlay* on top of a base at the specified *top* (row) and *left* (column) coordinates,
      # defaulting to center in both directions. ANSI styling on the base content is preserved underneath.
      def overlay(base, overlay, top: :center, left: :center)
        base_lines = base.to_s.lines(chomp: true)
        overlay_lines = overlay.to_s.lines(chomp: true)
        width = block_width(base_lines)
        row = offset(top, base_lines.length, overlay_lines.length)
        column = offset(left, width, block_width(overlay_lines))

        draw_lines(base_lines, overlay_lines, row: row, column: column, width: width)
      end

      # Places a *block* onto a blank canvas of *width* × *height* at an offset determined by *top* (row)
      # and *left* (column). Non-:center values are treated as absolute positions. When *background* is
      # given, the assembled frame is wrapped so the theme bg paints the entire canvas — overlay content
      # with its own bg overrides per-cell; resets re-apply the canvas bg.
      def place(block, width:, height:, top: 0, left: 0, background: nil)
        lines = block.to_s.lines(chomp: true)
        row = offset(top, height, lines.length)
        column = offset(left, width, block_width(lines))
        canvas = Array.new(height) { " " * width }
        composed = draw_lines(canvas, lines, row: row, column: column, width: width)
        return composed unless background

        Style.new.background(background).render(composed)
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

      # Computes a placement coordinate: if *value* is `:center` the result centres the *size* within *available*;
      # otherwise *value* is returned verbatim as an absolute integer position.
      def offset(value, available, size)
        return [(available - size) / 2, 0].max if value == :center

        value
      end

      # Merges an *overlay_line* into a *base_line* at the given *column*, returning the combined string. The
      # overlay replaces (covers) underlying characters; anything to the right that exceeds *width* is truncated.
      def composed_overlay_line(base_line, overlay_line, column, width)
        return visible_slice(base_line, 0, width) if column >= width
        return visible_slice(base_line, 0, width) if column + Width.measure(overlay_line) <= 0

        target_column = [column, 0].max
        overlay_start = [0 - column, 0].max
        overlay = visible_slice(overlay_line, overlay_start, width - target_column)
        overlay_width = Width.measure(overlay)
        return visible_slice(base_line, 0, width) if overlay_width.zero?

        right_column = target_column + overlay_width

        visible_slice(base_line, 0, target_column) +
          overlay +
          visible_slice(base_line, right_column, [width - right_column, 0].max)
      end

      # Returns a visible-slice of *line* starting at *start_column* spanning *width* characters, preserving any
      # ANSI escape sequences that were active at the start of the slice. Non-positive widths return `""`.
      def visible_slice(line, start_column, width)
        return "" unless width.positive?

        slice_visible_text(line.to_s, start_column, start_column + width)
      end

      # Slices a string by visible terminal columns while preserving ANSI style state.
      def slice_visible_text(line, start_column, end_column)
        state = {column: 0, output: +"", active: [], started: false, styled: false}

        each_ansi_or_char(line) do |token, ansi|
          if ansi
            slice_ansi(token, state, start_column, end_column)
          else
            slice_char(token, state, start_column, end_column)
          end
        end

        terminate_slice(state)
      end

      # Splits a *line* into token-range pieces bounded by *start_column* and *end_column*, preserving ANSI escapes
      # that fall within the visible range. Yields each character or escape sequence along with whether it is ANSI.
      def each_ansi_or_char(line)
        index = 0
        while index < line.length
          match = line.match(Width::ANSI_PATTERN, index)
          if match&.begin(0) == index
            yield match[0], true
            index = match.end(0)
          else
            char = line[index]
            yield char, false
            index += 1
          end
        end
      end

      # Slices an ANSI *token* (escape sequence) into *state*, writing active markers to the output if the current
      # *column* falls within the [start_column, end_column) range. Resets styles on `[0m` sequences.
      def slice_ansi(token, state, start_column, end_column)
        started = state[:started]
        update_active_styles(state[:active], token)
        return unless state[:column].between?(start_column, end_column - 1)

        start_slice(state)
        if started
          state[:output] << token
          state[:styled] = !token.include?("[0m")
        end
      end

      # Slices a plain *char* into *state*, advancing the column tracker by the character's visual width. If the
      # character overlaps with the [start_column, end_column) range it is appended to the output.
      def slice_char(char, state, start_column, end_column)
        char_width = Width.measure(char)
        char_start = state[:column]
        char_end = char_start + char_width
        state[:column] = char_end
        return unless char_end > start_column && char_start < end_column

        start_slice(state)
        state[:output] << char
      end

      # Starts writing to the output buffer, flushing any active ANSI markers if this is the first character placed.
      def start_slice(state)
        return if state[:started]

        state[:output] << state[:active].join
        state[:styled] = true unless state[:active].empty?
        state[:started] = true
      end

      # Closes the slice by appending a final `[0m` reset escape to the output unless no active styling exists or
      # nothing was written. Returns the fully constructed output string with trailing reset applied.
      def terminate_slice(state)
        return state[:output] if !state[:styled] || state[:output].empty?

        "#{state[:output]}\e[0m"
      end

      # Updates *state*[:active] with an ANSI *token*: resets all active styles on `[0m` or appends the token as a
      # new active marker otherwise. Called during each_ansi_or_char iteration.
      def update_active_styles(active, token)
        if token.include?("[0m")
          active.clear
        else
          active << token
        end
      end

      # Overlays *lines* onto a *canvas* starting at (*row*, *column*), writing each overlaid line into the canvas
      # via `composed_overlay_line`. Returns the final canvas joined by newlines.
      def draw_lines(canvas, lines, row:, column:, width:)
        lines.each_with_index do |line, index|
          line_index = row + index
          next if line_index.negative? || line_index >= canvas.length

          canvas[line_index] = composed_overlay_line(canvas[line_index], line, column, width)
        end

        canvas.join("\n")
      end
    end
  end
end
