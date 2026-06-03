# frozen_string_literal: true

module Charming
  module UI
    class ANSICodes
      ATTRIBUTES = {
        bold: 1,
        faint: 2,
        italic: 3,
        underline: 4,
        reverse: 7,
        strikethrough: 9
      }.freeze

      COLORS = {
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
        bright_black: 90,
        bright_red: 91,
        bright_green: 92,
        bright_yellow: 93,
        bright_blue: 94,
        bright_magenta: 95,
        bright_cyan: 96,
        bright_white: 97
      }.freeze

      def initialize(attributes:, foreground:, background:)
        @attributes = attributes
        @foreground = foreground
        @background = background
      end

      def codes
        @codes ||= attribute_codes +
          color_codes(@foreground, foreground: true) +
          color_codes(@background, foreground: false)
      end

      def apply(value)
        return value if codes.empty?

        start = "\e[#{codes.join(";")}m"
        value.split("\n", -1).map { |line| "#{start}#{line.gsub("\e[0m", "\e[0m#{start}")}\e[0m" }.join("\n")
      end

      private

      def attribute_codes
        @attributes.map { |attribute| ATTRIBUTES.fetch(attribute) }
      end

      def color_codes(color, foreground:)
        return [] unless color
        return indexed_color_code(color, foreground: foreground) if color.is_a?(Integer)
        return named_color_code(color, foreground: foreground) if COLORS.key?(color.to_sym)
        return truecolor_codes(color, foreground: foreground) if color.to_s.start_with?("#")

        raise ArgumentError, "unknown color: #{color.inspect}"
      end

      def named_color_code(color, foreground:)
        code = COLORS.fetch(color.to_sym)
        [foreground ? code : code + 10]
      end

      def indexed_color_code(color, foreground:)
        raise ArgumentError, "indexed color must be between 0 and 255" unless color.between?(0, 255)

        [foreground ? 38 : 48, 5, color]
      end

      def truecolor_codes(color, foreground:)
        hex = color.to_s.delete_prefix("#")
        raise ArgumentError, "truecolor must be #rrggbb" unless hex.match?(/\A[0-9a-fA-F]{6}\z/)

        [foreground ? 38 : 48, 2, hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
      end
    end
  end
end
