# frozen_string_literal: true

module Charming
  module UI
    class Style
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

      def initialize(options = {})
        @options = {
          attributes: [],
          padding: [0, 0, 0, 0],
          align: :left
        }.merge(options)
      end

      def foreground(color)
        with(foreground: color)
      end
      alias fg foreground

      def background(color)
        with(background: color)
      end
      alias bg background

      ATTRIBUTES.each_key do |attribute|
        define_method(attribute) do
          with(attributes: (@options.fetch(:attributes) + [attribute]).uniq)
        end
      end

      def padding(*values)
        with(padding: expand_box_values(values))
      end

      def border(style = :normal)
        with(border: style)
      end

      def width(value)
        with(width: value)
      end

      def height(value)
        with(height: value)
      end

      def align(value)
        with(align: value)
      end

      def render(value)
        lines = apply_dimensions(value.to_s.lines(chomp: true))
        lines = apply_padding(lines)
        lines = apply_border(lines)
        apply_ansi(lines.join("\n"))
      end

      private

      def with(changes)
        self.class.new(@options.merge(changes))
      end

      def apply_dimensions(lines)
        content_width = target_content_width(lines)
        dimensioned = lines.map { |line| align_line(line, content_width) }
        apply_height(dimensioned, content_width)
      end

      def target_content_width(lines)
        explicit_width = @options[:width]
        natural_width = lines.map { |line| Width.measure(line) }.max || 0
        [explicit_width || natural_width, natural_width].max
      end

      def apply_height(lines, width)
        height = @options[:height]
        return lines unless height

        lines + Array.new([height - lines.length, 0].max) { " " * width }
      end

      def apply_padding(lines)
        top, right, bottom, left = @options.fetch(:padding)
        inner_width = lines.map { |line| Width.measure(line) }.max || 0
        empty = " " * (left + inner_width + right)
        padded = lines.map do |line|
          pad_line(line, inner_width, left, right)
        end

        Array.new(top, empty) + padded + Array.new(bottom, empty)
      end

      def apply_border(lines)
        border_name = @options[:border]
        return lines unless border_name

        border = Border.fetch(border_name)
        width = lines.map { |line| Width.measure(line) }.max || 0
        horizontal = border.horizontal * width
        body = lines.map { |line| border_line(line, width, border) }

        [
          "#{border.top_left}#{horizontal}#{border.top_right}",
          *body,
          "#{border.bottom_left}#{horizontal}#{border.bottom_right}"
        ]
      end

      def pad_line(line, inner_width, left, right)
        (" " * left) + line + (" " * (inner_width - Width.measure(line) + right))
      end

      def border_line(line, width, border)
        "#{border.vertical}#{line}#{" " * (width - Width.measure(line))}#{border.vertical}"
      end

      def apply_ansi(value)
        codes = ansi_codes
        return value if codes.empty?

        "\e[#{codes.join(";")}m#{value}\e[0m"
      end

      def ansi_codes
        @options.fetch(:attributes).map { |attribute| ATTRIBUTES.fetch(attribute) } +
          color_codes(@options[:foreground], foreground: true) +
          color_codes(@options[:background], foreground: false)
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

      def align_line(line, width)
        remaining = width - Width.measure(line)
        return line if remaining <= 0

        case @options.fetch(:align)
        when :right
          (" " * remaining) + line
        when :center
          left = remaining / 2
          (" " * left) + line + (" " * (remaining - left))
        else
          line + (" " * remaining)
        end
      end

      def expand_box_values(values)
        case values.length
        when 1 then [values[0], values[0], values[0], values[0]]
        when 2 then [values[0], values[1], values[0], values[1]]
        when 4 then values
        else
          raise ArgumentError, "padding expects 1, 2, or 4 values"
        end
      end
    end
  end
end
