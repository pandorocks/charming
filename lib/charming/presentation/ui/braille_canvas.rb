# frozen_string_literal: true

module Charming
  module UI
    # BrailleCanvas is a monochrome subpixel drawing surface backed by Unicode braille glyphs
    # (U+2800–U+28FF). Each character cell packs a 2×4 grid of dots, so the canvas addresses
    # `width`×`height` *pixels* while rendering to `cols`×`rows` *cells* — 8× the vertical and 2× the
    # horizontal resolution of plain text. It's pure text (works on every terminal) and composes via
    # `row`/`column`/`Canvas` like any other block. Used by {Charming::Components::Chart}.
    class BrailleCanvas
      # The first braille code point; OR-ing dot bits onto it yields the glyph for a cell.
      BASE = 0x2800

      # Dot bit for each (x%2, y%4) position within a cell, indexed `DOTS[y % 4][x % 2]`.
      DOTS = [[0x01, 0x08], [0x02, 0x10], [0x04, 0x20], [0x40, 0x80]].freeze

      # *width* and *height* are the drawable area in pixels (dots).
      def initialize(width, height)
        @width = width
        @height = height
        @cols = (width + 1) / 2
        @rows = (height + 3) / 4
        @cells = Array.new(@rows) { Array.new(@cols, 0) }
      end

      attr_reader :width, :height, :cols, :rows

      # Turns the dot at pixel (*x*, *y*) on (or off when `on: false`). Out-of-range points are
      # ignored. Returns self for chaining.
      def set(x, y, on: true)
        return self unless x.between?(0, @width - 1) && y.between?(0, @height - 1)

        bit = DOTS[y % 4][x % 2]
        if on
          @cells[y / 4][x / 2] |= bit
        else
          @cells[y / 4][x / 2] &= ~bit
        end
        self
      end

      # Turns the dot at pixel (*x*, *y*) off. Returns self.
      def unset(x, y)
        set(x, y, on: false)
      end

      # Draws a straight line between (*x0*, *y0*) and (*x1*, *y1*) with Bresenham's algorithm.
      # Returns self.
      def line(x0, y0, x1, y1)
        dx = (x1 - x0).abs
        dy = -(y1 - y0).abs
        sx = (x0 < x1) ? 1 : -1
        sy = (y0 < y1) ? 1 : -1
        err = dx + dy
        x = x0
        y = y0
        loop do
          set(x, y)
          break if x == x1 && y == y1

          e2 = 2 * err
          if e2 >= dy
            err += dy
            x += sx
          end
          if e2 <= dx
            err += dx
            y += sy
          end
        end
        self
      end

      # Renders the canvas as `rows` lines of `cols` braille glyphs.
      def to_s
        @cells.map { |row| row.map { |bits| (BASE + bits).chr(Encoding::UTF_8) }.join }.join("\n")
      end
    end
  end
end
