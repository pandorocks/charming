# frozen_string_literal: true

module Charming
  module UI
    module_function

    def style
      Style.new
    end

    def join_horizontal(*blocks, gap: 0)
      normalized = normalize_blocks(blocks)
      widths = block_widths(normalized)
      separator = " " * gap

      Array.new(block_height(normalized)) do |index|
        horizontal_line(normalized, widths, index).join(separator)
      end.join("\n")
    end

    def join_vertical(*blocks, gap: 0)
      blocks.join("\n" * (gap + 1))
    end

    def center(block, width:, height:)
      place(block, width: width, height: height, top: :center, left: :center)
    end

    def overlay(base, overlay, top: :center, left: :center)
      base_lines = base.to_s.lines(chomp: true)
      overlay_lines = overlay.to_s.lines(chomp: true)
      width = block_width(base_lines)
      row = offset(top, base_lines.length, overlay_lines.length)
      column = offset(left, width, block_width(overlay_lines))

      draw_lines(base_lines, overlay_lines, row: row, column: column, width: width)
    end

    def place(block, width:, height:, top: 0, left: 0)
      lines = block.to_s.lines(chomp: true)
      row = offset(top, height, lines.length)
      column = offset(left, width, block_width(lines))
      canvas = Array.new(height) { " " * width }

      draw_lines(canvas, lines, row: row, column: column, width: width)
    end

    def normalize_blocks(blocks)
      blocks.map { |block| block.to_s.lines(chomp: true) }
    end

    def block_widths(blocks)
      blocks.map { |lines| lines.map { |line| Width.measure(line) }.max || 0 }
    end

    def block_width(lines)
      lines.map { |line| Width.measure(line) }.max || 0
    end

    def block_height(blocks)
      blocks.map(&:length).max || 0
    end

    def horizontal_line(blocks, widths, index)
      blocks.each_with_index.map do |lines, block_index|
        line = lines[index] || ""
        line + (" " * (widths[block_index] - Width.measure(line)))
      end
    end

    def offset(value, available, size)
      return [(available - size) / 2, 0].max if value == :center

      value
    end

    def composed_overlay_line(base_line, overlay_line, column, width)
      overlay_width = Width.measure(overlay_line)
      right_column = column + overlay_width

      visible_slice(base_line, 0, column) +
        overlay_line +
        visible_slice(base_line, right_column, [width - right_column, 0].max)
    end

    def visible_slice(line, start_column, width)
      return "" unless width.positive?

      slice_visible_text(line.to_s, start_column, start_column + width)
    end

    def slice_visible_text(line, start_column, end_column)
      state = {active: [], column: 0, output: +"", started: false}

      each_ansi_or_char(line) do |token, ansi|
        ansi ? slice_ansi(token, state, start_column, end_column) : slice_char(token, state, start_column, end_column)
        break if state[:column] >= end_column
      end

      terminate_slice(state)
    end

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

    def slice_ansi(token, state, start_column, end_column)
      started = state[:started]
      update_active_styles(state[:active], token)
      return unless state[:column].between?(start_column, end_column - 1)

      start_slice(state)
      state[:output] << token if started
    end

    def slice_char(char, state, start_column, end_column)
      char_width = Width.measure(char)
      char_start = state[:column]
      char_end = char_start + char_width
      state[:column] = char_end
      return unless char_end > start_column && char_start < end_column

      start_slice(state)
      state[:output] << char
    end

    def start_slice(state)
      return if state[:started]

      state[:output] << state[:active].join
      state[:started] = true
    end

    def terminate_slice(state)
      return state[:output] if state[:active].empty? || state[:output].empty?

      "#{state[:output]}\e[0m"
    end

    def update_active_styles(active, token)
      if token.include?("[0m")
        active.clear
      else
        active << token
      end
    end

    def draw_lines(canvas, lines, row:, column:, width:)
      lines.each_with_index do |line, index|
        line_index = row + index
        canvas[line_index] = composed_overlay_line(canvas[line_index], line, column, width)
      end

      canvas.join("\n")
    end
  end
end
