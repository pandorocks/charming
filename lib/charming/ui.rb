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

    def normalize_blocks(blocks)
      blocks.map { |block| block.to_s.lines(chomp: true) }
    end

    def block_widths(blocks)
      blocks.map { |lines| lines.map { |line| Width.measure(line) }.max || 0 }
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
  end
end
