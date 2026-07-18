# frozen_string_literal: true

module Charming
  module UI
    # Gradient interpolates between two hex colors: blend a single point, build
    # an evenly spaced ramp, or paint text with a per-character color sweep.
    module Gradient
      module_function

      # Blends *start_hex* and *end_hex* ("#rrggbb") at fractional *amount*
      # (0.0 → start, 1.0 → end), returning a "#rrggbb" string.
      def blend(start_hex, end_hex, amount)
        mixed = rgb(start_hex).zip(rgb(end_hex)).map do |from, to|
          (from + ((to - from) * amount)).round
        end
        format("#%02x%02x%02x", *mixed)
      end

      # An evenly spaced ramp of *count* colors from *start_hex* to *end_hex*,
      # endpoints included.
      def steps(start_hex, end_hex, count)
        return [blend(start_hex, end_hex, 0.0)] if count <= 1

        Array.new(count) { |index| blend(start_hex, end_hex, index.to_f / (count - 1)) }
      end

      # Paints each grapheme cluster of plain-text *text* with a foreground color
      # swept from *from* to *to* across its visible characters.
      def colorize(text, from:, to:)
        clusters = text.to_s.scan(Width::GRAPHEME)
        span = [clusters.length - 1, 1].max

        clusters.each_with_index.map do |cluster, index|
          Style.new(foreground: blend(from, to, index.to_f / span)).render(cluster)
        end.join
      end

      # Decomposes "#rrggbb" into [r, g, b] integers.
      def rgb(hex)
        value = hex.to_s.delete_prefix("#")
        raise ArgumentError, "gradient colors must be #rrggbb" unless value.match?(/\A[0-9a-fA-F]{6}\z/)

        [value[0..1], value[2..3], value[4..5]].map { |part| part.to_i(16) }
      end
    end
  end
end
