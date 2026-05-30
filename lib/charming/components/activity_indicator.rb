# frozen_string_literal: true

module Charming
  module Components
    class ActivityIndicator < Component
      DEFAULT_CHARS = "0123456789abcdefABCDEF~!@#$%^&*+=_".chars.freeze
      DEFAULT_GRADIENT = ["#ff0000", "#0000ff"].freeze
      DEFAULT_LABEL_COLOR = "#cccccc"
      ELLIPSIS_FRAMES = [".", "..", "...", ""].freeze
      FRAME_COUNT = 10
      FNV_OFFSET = 2_166_136_261
      FNV_PRIME = 16_777_619
      FNV_MASK = 0xffffffff

      attr_reader :width, :label, :index, :seed, :chars, :gradient, :label_style

      def initialize(width: 10, label: nil, index: 0, seed: 0, chars: DEFAULT_CHARS,
        gradient: DEFAULT_GRADIENT, label_style: nil)
        super()
        raise ArgumentError, "chars cannot be empty" if chars.empty?

        @width = [width.to_i, 1].max
        @label = label
        @index = index.to_i
        @seed = seed
        @chars = chars.map(&:to_s)
        @gradient = gradient
        @label_style = label_style
      end

      def tick(count = 1)
        @index += count.to_i
        self
      end

      def render
        return indicator unless label

        "#{indicator} #{styled_label}#{styled_ellipsis}"
      end

      private

      def indicator
        Array.new(width) { |position| styled_char(position) }.join
      end

      def styled_char(position)
        style.foreground(color_at(position)).render(char_at(position))
      end

      def char_at(position)
        chars.fetch(stable_hash("#{seed}:#{frame}:#{position}") % chars.length)
      end

      def styled_label
        label_style_or_default.render(label.to_s)
      end

      def styled_ellipsis
        label_style_or_default.render(ellipsis_frame)
      end

      def ellipsis_frame
        ELLIPSIS_FRAMES.fetch((index / 4) % ELLIPSIS_FRAMES.length)
      end

      def label_style_or_default
        label_style || style.foreground(DEFAULT_LABEL_COLOR)
      end

      def color_at(position)
        return gradient.first unless width > 1

        blend(gradient.first, gradient.last, position / (width - 1).to_f)
      end

      def blend(start_hex, end_hex, amount)
        start_rgb = rgb(start_hex)
        end_rgb = rgb(end_hex)
        mixed = start_rgb.zip(end_rgb).map { |from, to| (from + ((to - from) * amount)).round }
        "#%02x%02x%02x" % mixed
      end

      def rgb(hex)
        value = hex.to_s.delete_prefix("#")
        raise ArgumentError, "gradient colors must be #rrggbb" unless value.match?(/\A[0-9a-fA-F]{6}\z/)

        [value[0..1], value[2..3], value[4..5]].map { |part| part.to_i(16) }
      end

      def frame
        index % FRAME_COUNT
      end

      def stable_hash(value)
        value.bytes.reduce(FNV_OFFSET) do |hash, byte|
          ((hash ^ byte) * FNV_PRIME) & FNV_MASK
        end
      end
    end
  end
end
