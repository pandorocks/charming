# frozen_string_literal: true

module Charming
  module UI
    # Style is an immutable builder for terminal text styling. Every method returns a new
    # Style instance with the requested attribute added, so styles can be safely chained and
    # shared across views. `render(value)` applies the accumulated style to a string.
    class Style
      ATTRIBUTES = ANSICodes::ATTRIBUTES

      COLORS = ANSICodes::COLORS

      # Initializes a new style with an optional options hash. Recognized keys: `:attributes`
      # (array of attribute symbols), `:padding` ([top, right, bottom, left]), `:align`
      # (`:left`/`:right`/`:center`), and any of `:foreground`, `:background`, `:border`,
      # `:border_sides`, `:border_foreground`, `:width`, `:height`.
      def initialize(options = {})
        @options = {
          attributes: [],
          padding: [0, 0, 0, 0],
          align: :left
        }.merge(options)
      end

      # Returns a new Style with the foreground *color* set. *color* is a color name (":red"),
      # 256-color index (integer), or hex string ("#rrggbb").
      def foreground(color)
        with(foreground: color)
      end
      alias_method :fg, :foreground

      # Returns a new Style with the background *color* set.
      def background(color)
        with(background: color)
      end
      alias_method :bg, :background

      # Attribute methods (bold, italic, underline, …) are defined dynamically by the
      # metaprogramming loop below. Each toggles a single text attribute on the style.
      ATTRIBUTES.each_key do |attribute|
        define_method(attribute) do
          with(attributes: (@options.fetch(:attributes) + [attribute]).uniq)
        end
      end

      # Returns a new Style with the padding set. Accepts 1, 2, or 4 values following CSS-style
      # shorthand: 1 → all sides, 2 → [vertical, horizontal], 4 → [top, right, bottom, left].
      def padding(*values)
        with(padding: expand_box_values(values))
      end

      # Returns a new Style with the border set. *style* is a border name (e.g., :normal,
      # :rounded). *sides* optionally restricts the border to specific sides. *foreground*
      # sets the border color.
      def border(style = :normal, sides: nil, foreground: nil)
        with(border: style, border_sides: sides, border_foreground: foreground)
      end

      # Returns a new Style that fixes the rendered width to *value* (in display columns).
      def width(value)
        with(width: value)
      end

      # Returns a new Style that fixes the rendered height to *value* (in rows).
      def height(value)
        with(height: value)
      end

      # Returns a new Style with horizontal alignment set (`:left`, `:right`, or `:center`).
      def align(value)
        with(align: value)
      end

      # Applies the configured style to *value* and returns the styled string. Steps:
      # 1. wrap to `:width`, 2. align horizontally, 3. expand to `:height`, 4. apply padding,
      # 5. paint border, 6. emit ANSI attribute/foreground/background escapes.
      def render(value)
        lines = apply_dimensions(value.to_s.lines(chomp: true))
        lines = apply_padding(lines)
        lines = apply_border(lines)
        apply_ansi(lines.join("\n"))
      end

      private

      # Returns a copy of self with *changes* merged into the options hash.
      def with(changes)
        self.class.new(@options.merge(changes))
      end

      # Wraps each line to the target width and applies horizontal alignment, then expands
      # to the target height.
      def apply_dimensions(lines)
        content_width = target_content_width(lines)
        dimensioned = lines.map { |line| align_line(fit_line(line, content_width), content_width) }
        apply_height(dimensioned, content_width)
      end

      # Returns the target content width: the explicit :width if set, otherwise the natural
      # max display width of the lines.
      def target_content_width(lines)
        explicit_width = @options[:width]
        explicit_width || Width.widest(lines)
      end

      # Clips *line* to *width* display columns, preserving ANSI styling where possible.
      def fit_line(line, width)
        return line if Width.measure(line) <= width

        UI.visible_slice(line, 0, width)
      end

      # Truncates or pads the lines array to *height* rows, filling with blank rows.
      def apply_height(lines, width)
        height = @options[:height]
        return lines unless height

        visible = lines.first(height)
        visible + Array.new([height - visible.length, 0].max) { " " * width }
      end

      # Applies padding by prepending/appending blank rows (vertical) and indenting each
      # line (horizontal).
      def apply_padding(lines)
        top, right, bottom, left = @options.fetch(:padding)
        inner_width = Width.widest(lines)
        empty = " " * (left + inner_width + right)
        padded = lines.map do |line|
          pad_line(line, inner_width, left, right)
        end

        Array.new(top, empty) + padded + Array.new(bottom, empty)
      end

      # Paints the configured border around the lines, when :border is set.
      def apply_border(lines)
        border_name = @options[:border]
        return lines unless border_name

        border_painter(border_name).paint(lines, content_width(lines))
      end

      # Pads a single line to *inner_width*, with *left* and *right* padding spaces.
      def pad_line(line, inner_width, left, right)
        (" " * left) + Width.pad_to(line, inner_width) + (" " * right)
      end

      # Builds a BorderPainter configured for the current border options.
      def border_painter(border_name)
        BorderPainter.new(
          border: Border.fetch(border_name),
          sides: @options[:border_sides],
          foreground: @options[:border_foreground],
          background: @options[:background]
        )
      end

      # Returns the natural display width of the longest line in *lines*.
      def content_width(lines)
        Width.widest(lines)
      end

      # Applies the active ANSI attribute/foreground/background codes to *value*.
      def apply_ansi(value)
        ansi_codes_obj.apply(value)
      end

      # The list of active ANSI escape sequence strings (attribute + foreground + background).
      def ansi_codes
        ansi_codes_obj.codes
      end

      # Builds an ANSICodes object from the active attributes, foreground, and background.
      def ansi_codes_obj
        ANSICodes.new(
          attributes: @options.fetch(:attributes),
          foreground: @options[:foreground],
          background: @options[:background]
        )
      end

      # Pads *line* on the left or right (or both, for :center) according to :align.
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

      # Normalizes 1/2/4 padding value arguments into a [top, right, bottom, left] array.
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
