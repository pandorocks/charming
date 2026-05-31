# frozen_string_literal: true

require "json"

module Charming
  module UI
    class Theme
      BUILT_IN_ROOT = File.expand_path("themes", __dir__)

      DEFAULT_TOKENS = {
        text: {foreground: :bright_white},
        title: {foreground: :bright_cyan, bold: true},
        muted: {foreground: :bright_black},
        border: {foreground: :bright_magenta},
        selected: {reverse: true},
        info: {foreground: :bright_cyan},
        warn: {foreground: :yellow}
      }.freeze

      def self.default
        @default ||= load_builtin("phosphor")
      end

      def self.load_file(path)
        from_hash(JSON.parse(File.read(path)))
      end

      def self.load_builtin(name)
        load_file(built_in_path(name))
      end

      def self.built_in_names
        Dir.glob(File.join(BUILT_IN_ROOT, "*.json")).map { |path| File.basename(path, ".json") }.sort
      end

      def self.from_hash(value)
        raise ArgumentError, "theme file must contain an object" unless value.is_a?(Hash)

        styles = value.fetch("styles") do
          raise ArgumentError, "theme file must contain styles"
        end

        palette = value.fetch("palette", {})
        new(
          resolve_palette_references(styles, palette),
          background: resolve_background(value["background"], palette)
        )
      end

      def self.resolve_background(value, palette)
        return unless value

        deep_resolve_colors(value, normalize_colors(palette))
      end

      def self.built_in_path(name)
        slug = name.to_s
        raise ArgumentError, "unknown built-in theme: #{name.inspect}" unless built_in_names.include?(slug)

        File.join(BUILT_IN_ROOT, "#{slug}.json")
      end

      def self.resolve_palette_references(styles, palette)
        palette = normalize_colors(palette)
        deep_resolve_colors(styles, palette)
      end

      def self.deep_resolve_colors(value, palette)
        case value
        when Hash
          value.transform_values { |item| deep_resolve_colors(item, palette) }
        when Array
          value.map { |item| deep_resolve_colors(item, palette) }
        when String
          palette.fetch(value, normalize_color(value) || value)
        else
          value
        end
      end

      def self.normalize_colors(values)
        values.transform_values { |value| normalize_color(value) }.compact
      end

      def self.normalize_color(value)
        return unless value.is_a?(String)

        case value
        when /\A#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])(?:[0-9a-fA-F])?\z/
          "#{$1 * 2}#{$2 * 2}#{$3 * 2}".prepend("#")
        when /\A#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?\z/
          value[0, 7]
        end
      end

      attr_reader :background

      def initialize(tokens = {}, background: nil)
        @tokens = symbolize_keys(tokens)
        @background = background
      end

      def style(name)
        spec = @tokens.fetch(name.to_sym) do
          raise ArgumentError, "unknown theme token: #{name.inspect}"
        end

        build_style(spec)
      end
      alias_method :[], :style

      def method_missing(name, ...)
        return style(name) if @tokens.key?(name)

        super
      end

      def respond_to_missing?(name, include_private = false)
        @tokens.key?(name) || super
      end

      private

      def build_style(spec)
        return spec if spec.is_a?(Style)
        return UI.style.foreground(spec) unless spec.is_a?(Hash)

        apply_options(UI.style, symbolize_keys(spec))
      end

      def apply_options(base_style, spec)
        styled = apply_colors(base_style, spec)
        styled = apply_attributes(styled, spec)
        apply_layout(styled, spec)
      end

      def apply_colors(base_style, spec)
        styled = base_style
        styled = styled.foreground(spec[:foreground] || spec[:fg]) if spec.key?(:foreground) || spec.key?(:fg)
        styled = styled.background(spec[:background] || spec[:bg]) if spec.key?(:background) || spec.key?(:bg)
        styled
      end

      def apply_attributes(base_style, spec)
        Style::ATTRIBUTES.each_key.reduce(base_style) do |styled, attribute|
          spec[attribute] ? styled.public_send(attribute) : styled
        end
      end

      def apply_layout(base_style, spec)
        styled = base_style
        styled = styled.padding(*Array(spec[:padding])) if spec.key?(:padding)
        styled = apply_border(styled, spec[:border]) if spec.key?(:border)
        styled = styled.width(spec[:width]) if spec.key?(:width)
        styled = styled.height(spec[:height]) if spec.key?(:height)
        styled = styled.align(spec[:align].to_sym) if spec.key?(:align)
        styled
      end

      def apply_border(base_style, border_spec)
        return base_style.border(border_spec) unless border_spec.is_a?(Hash)

        border_spec = symbolize_keys(border_spec)
        base_style.border(
          border_spec.fetch(:style, :normal),
          sides: border_spec[:sides],
          foreground: border_spec[:foreground] || border_spec[:fg]
        )
      end

      def symbolize_keys(value)
        value.each_with_object({}) do |(key, item), result|
          result[key.to_sym] = item.is_a?(Hash) ? symbolize_keys(item) : item
        end
      end
    end
  end
end
