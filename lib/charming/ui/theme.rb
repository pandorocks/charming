# frozen_string_literal: true

require "json"

module Charming
  module UI
    class Theme
      BUILT_IN_ROOT = File.expand_path("themes/opencode", __dir__)

      DEFAULT_TOKENS = {
        primary: {foreground: :bright_cyan},
        muted: {foreground: :bright_black},
        border: {foreground: :bright_magenta},
        selection: {reverse: true},
        danger: {foreground: :red},
        success: {foreground: :green},
        warning: {foreground: :yellow}
      }.freeze

      def self.default
        @default ||= new(DEFAULT_TOKENS)
      end

      def self.load_file(path, variant: :dark)
        from_opencode(JSON.parse(File.read(path)), variant: variant)
      end

      def self.load_builtin(name, variant: :dark)
        load_file(built_in_path(name), variant: variant)
      end

      def self.built_in_names
        Dir.glob(File.join(BUILT_IN_ROOT, "*.json")).map { |path| File.basename(path, ".json") }.sort
      end

      def self.from_opencode(value, variant: :dark)
        raise ArgumentError, "theme file must contain an object" unless value.is_a?(Hash)

        selected = value.fetch(variant.to_s) do
          raise ArgumentError, "unknown theme variant: #{variant.inspect}"
        end
        palette = selected.fetch("palette") do
          raise ArgumentError, "theme variant must contain a palette"
        end
        overrides = selected.fetch("overrides", {})

        new(opencode_tokens(palette, overrides))
      end

      def self.built_in_path(name)
        slug = name.to_s
        raise ArgumentError, "unknown built-in theme: #{name.inspect}" unless built_in_names.include?(slug)

        File.join(BUILT_IN_ROOT, "#{slug}.json")
      end

      def self.opencode_tokens(palette, overrides)
        palette = normalize_colors(palette)
        overrides = normalize_colors(overrides)
        primary = palette.fetch("primary")
        neutral = palette.fetch("neutral")
        ink = palette.fetch("ink")
        success = palette.fetch("success")
        warning = palette.fetch("warning")
        error = palette.fetch("error")
        info = palette.fetch("info")

        {
          text: ink,
          background: {background: neutral},
          primary: primary,
          muted: overrides["text-weak"] || overrides["syntax-comment"] || ink,
          border: palette["accent"] || primary,
          selection: {foreground: neutral, background: primary},
          danger: error,
          error: error,
          success: success,
          warning: warning,
          info: info,
          accent: palette["accent"] || primary,
          diff_add: palette["diffAdd"] || success,
          diff_delete: palette["diffDelete"] || error
        }
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

      def initialize(tokens = {})
        @tokens = symbolize_keys(tokens)
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
        styled = styled.border(spec[:border]) if spec.key?(:border)
        styled = styled.width(spec[:width]) if spec.key?(:width)
        styled = styled.height(spec[:height]) if spec.key?(:height)
        styled = styled.align(spec[:align].to_sym) if spec.key?(:align)
        styled
      end

      def symbolize_keys(value)
        value.each_with_object({}) do |(key, item), result|
          result[key.to_sym] = item.is_a?(Hash) ? symbolize_keys(item) : item
        end
      end
    end
  end
end
