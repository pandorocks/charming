# frozen_string_literal: true

require_relative "ui/border"
require_relative "ui/style"
require_relative "ui/width"

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

    def padded_overlay_line(line, column, width)
      right = [width - column - Width.measure(line), 0].max
      (" " * column) + line + (" " * right)
    end

    def draw_lines(canvas, lines, row:, column:, width:)
      lines.each_with_index do |line, index|
        canvas[row + index] = padded_overlay_line(line, column, width)
      end

      canvas.join("\n")
    end
  end
end
