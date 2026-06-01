# frozen_string_literal: true

module Charming
  module Presentation
    module UI
      class Style
        ATTRIBUTES = ANSICodes::ATTRIBUTES

        COLORS = ANSICodes::COLORS

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
        alias_method :fg, :foreground

        def background(color)
          with(background: color)
        end
        alias_method :bg, :background

        ATTRIBUTES.each_key do |attribute|
          define_method(attribute) do
            with(attributes: (@options.fetch(:attributes) + [attribute]).uniq)
          end
        end

        def padding(*values)
          with(padding: expand_box_values(values))
        end

        def border(style = :normal, sides: nil, foreground: nil)
          with(border: style, border_sides: sides, border_foreground: foreground)
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
          dimensioned = lines.map { |line| align_line(fit_line(line, content_width), content_width) }
          apply_height(dimensioned, content_width)
        end

        def target_content_width(lines)
          explicit_width = @options[:width]
          natural_width = lines.map { |line| Width.measure(line) }.max || 0
          explicit_width || natural_width
        end

        def fit_line(line, width)
          return line if Width.measure(line) <= width

          UI.visible_slice(line, 0, width)
        end

        def apply_height(lines, width)
          height = @options[:height]
          return lines unless height

          visible = lines.first(height)
          visible + Array.new([height - visible.length, 0].max) { " " * width }
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

          border_painter(border_name).paint(lines, content_width(lines))
        end

        def pad_line(line, inner_width, left, right)
          (" " * left) + line + (" " * (inner_width - Width.measure(line) + right))
        end

        def border_painter(border_name)
          BorderPainter.new(
            border: Border.fetch(border_name),
            sides: @options[:border_sides],
            foreground: @options[:border_foreground],
            background: @options[:background]
          )
        end

        def content_width(lines)
          lines.map { |line| Width.measure(line) }.max || 0
        end

        def apply_ansi(value)
          ansi_codes_obj.apply(value)
        end

        def ansi_codes
          ansi_codes_obj.codes
        end

        def ansi_codes_obj
          ANSICodes.new(
            attributes: @options.fetch(:attributes),
            foreground: @options[:foreground],
            background: @options[:background]
          )
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
end
