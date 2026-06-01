# frozen_string_literal: true

module Charming
  module Presentation
    module UI
      # Canvas is a 2D character grid of fixed width and height that supports
      # placing content at (row, column) coordinates and overlaying one block
      # on top of another. Construct via .new(width, height) for a blank grid
      # or .parse(string) to reconstruct from rendered output.
      class Canvas
        def initialize(width, height)
          @width = width
          @height = height
          @grid = Array.new(height) { " " * width }
        end

        def self.parse(string)
          lines = string.to_s.lines(chomp: true)
          width = UI.block_width(lines)
          canvas = new(width, lines.length)
          lines.each_with_index { |line, i| canvas.instance_variable_get(:@grid)[i] = line }
          canvas
        end

        def to_s
          @grid.join("\n")
        end

        def place(block, top: 0, left: 0, background: nil)
          lines = block.to_s.lines(chomp: true)
          row = Canvas.offset(top, @height, lines.length)
          column = Canvas.offset(left, @width, UI.block_width(lines))
          draw_lines(lines, row: row, column: column, onto: @grid)
          rendered = to_s
          background ? UI::Style.new.background(background).render(rendered) : rendered
        end

        def overlay(other, top: :center, left: :center)
          overlay_lines = other.to_s.lines(chomp: true)
          row = Canvas.offset(top, @grid.length, overlay_lines.length)
          column = Canvas.offset(left, @width, UI.block_width(overlay_lines))
          draw_lines(overlay_lines, row: row, column: column, onto: @grid)
          self
        end

        def self.offset(value, available, size)
          return [(available - size) / 2, 0].max if value == :center

          value
        end

        private

        def draw_lines(lines, row:, column:, onto:)
          lines.each_with_index do |line, index|
            line_index = row + index
            next if line_index.negative? || line_index >= onto.length

            onto[line_index] = compose_line(onto[line_index], line, column)
          end
        end

        def compose_line(base_line, overlay_line, column)
          return ANSISlicer.slice(base_line, 0, @width) if column >= @width
          return ANSISlicer.slice(base_line, 0, @width) if column + Width.measure(overlay_line) <= 0

          target_column = [column, 0].max
          overlay_start = [0 - column, 0].max
          overlay = ANSISlicer.slice(overlay_line, overlay_start, @width - target_column)
          overlay_width = Width.measure(overlay)
          return ANSISlicer.slice(base_line, 0, @width) if overlay_width.zero?

          right_column = target_column + overlay_width

          ANSISlicer.slice(base_line, 0, target_column) +
            overlay +
            ANSISlicer.slice(base_line, right_column, [@width - right_column, 0].max)
        end
      end
    end
  end
end
