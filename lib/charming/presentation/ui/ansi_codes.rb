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

      # Resolves *color* to SGR codes, downconverting to the terminal's capability
      # (see UI::ColorSupport): truecolor → 256 → 16 → none. Adaptive colors
      # resolve against the terminal background first.
      def color_codes(color, foreground:)
        color = color.resolve if color.respond_to?(:resolve)
        return [] unless color
        return [] if ColorSupport.level == :none
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
        return basic_color_code(ColorSupport.index_to_16(color), foreground: foreground) unless ColorSupport.at_least?(:color256)

        [foreground ? 38 : 48, 5, color]
      end

      def truecolor_codes(color, foreground:)
        hex = color.to_s.delete_prefix("#")
        hex = hex.chars.map { |digit| digit * 2 }.join if hex.match?(/\A[0-9a-fA-F]{3}\z/)
        raise ArgumentError, "truecolor must be #rgb or #rrggbb" unless hex.match?(/\A[0-9a-fA-F]{6}\z/)
        return [foreground ? 38 : 48, 5, ColorSupport.hex_to_256(hex)] if ColorSupport.level == :color256
        return basic_color_code(ColorSupport.hex_to_16(hex), foreground: foreground) if ColorSupport.level == :color16

        [foreground ? 38 : 48, 2, hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
      end

      # Wraps a basic SGR foreground code (30-37/90-97) for the requested plane.
      def basic_color_code(code, foreground:)
        [foreground ? code : code + 10]
      end
    end
  end
end
