# frozen_string_literal: true

module Charming
  module UI
    # ColorSupport detects the terminal's color capability and downconverts colors so
    # themes written in truecolor degrade gracefully on less-capable terminals.
    #
    # Levels (best to worst): :truecolor, :color256, :color16, :none.
    #
    # Detection honors NO_COLOR, then COLORTERM (truecolor/24bit), then TERM.
    # `UI::ColorSupport.level = :color256` overrides detection (useful in tests and
    # for user preference).
    module ColorSupport
      LEVELS = %i[none color16 color256 truecolor].freeze

      # The 6-level RGB ramp used by the xterm 256-color cube (indices 16-231).
      CUBE_LEVELS = [0, 95, 135, 175, 215, 255].freeze

      module_function

      # The active color level: the explicit override or the detected level (memoized).
      def level
        @level ||= detect(ENV)
      end

      # Overrides the detected level (nil resets to auto-detection on next access).
      def level=(value)
        raise ArgumentError, "unknown color level: #{value.inspect}" if value && !LEVELS.include?(value)

        @level = value
      end

      # Detects the color capability from an environment hash.
      def detect(env)
        return :none if env["NO_COLOR"] && !env["NO_COLOR"].empty?
        return :truecolor if %w[truecolor 24bit].include?(env["COLORTERM"])

        term = env["TERM"].to_s
        return :none if term.empty? || term == "dumb"
        return :truecolor if term.include?("direct")
        return :color256 if term.include?("256color")

        :color16
      end

      # True when the active level is at least *required* (e.g., `at_least?(:color256)`).
      def at_least?(required)
        LEVELS.index(level) >= LEVELS.index(required)
      end

      # Converts "#rrggbb" to the nearest xterm 256-color index (cube or grayscale ramp).
      def hex_to_256(hex)
        r, g, b = hex_components(hex)
        cube = cube_index(r, g, b)
        gray = gray_index(r, g, b)
        (color_distance([r, g, b], index_to_rgb(cube)) <= color_distance([r, g, b], index_to_rgb(gray))) ? cube : gray
      end

      # Converts "#rrggbb" to the nearest of the 16 basic ANSI colors, returned as the
      # SGR foreground code (30-37 or 90-97).
      def hex_to_16(hex)
        rgb = hex_components(hex)
        best = basic_palette.min_by { |_code, basic_rgb| color_distance(rgb, basic_rgb) }
        best.first
      end

      # Converts a 256-color index to the nearest basic ANSI SGR foreground code.
      def index_to_16(index)
        rgb = index_to_rgb(index)
        best = basic_palette.min_by { |_code, basic_rgb| color_distance(rgb, basic_rgb) }
        best.first
      end

      # -- conversion internals ----------------------------------------------------

      def hex_components(hex)
        digits = hex.to_s.delete_prefix("#")
        [digits[0..1].to_i(16), digits[2..3].to_i(16), digits[4..5].to_i(16)]
      end

      # Index in the 6x6x6 cube (16-231) closest to the RGB triple.
      def cube_index(r, g, b)
        16 + (36 * nearest_cube_level(r)) + (6 * nearest_cube_level(g)) + nearest_cube_level(b)
      end

      # Index in the grayscale ramp (232-255) closest to the RGB triple's luminance.
      def gray_index(r, g, b)
        gray = ((r + g + b) / 3.0).round
        step = ((gray - 8) / 10.0).round.clamp(0, 23)
        232 + step
      end

      def nearest_cube_level(component)
        CUBE_LEVELS.each_index.min_by { |index| (CUBE_LEVELS[index] - component).abs }
      end

      # The RGB triple a 256-color *index* renders as.
      def index_to_rgb(index)
        if index >= 232
          gray = 8 + (index - 232) * 10
          [gray, gray, gray]
        elsif index >= 16
          offset = index - 16
          [CUBE_LEVELS[offset / 36], CUBE_LEVELS[(offset / 6) % 6], CUBE_LEVELS[offset % 6]]
        else
          basic_palette.find { |code, _| basic_index_for_code(code) == index }&.last || [0, 0, 0]
        end
      end

      def color_distance(a, b)
        (a[0] - b[0])**2 + (a[1] - b[1])**2 + (a[2] - b[2])**2
      end

      # The 16 basic ANSI colors as [SGR foreground code, RGB] pairs.
      def basic_palette
        @basic_palette ||= {
          30 => [0, 0, 0], 31 => [205, 49, 49], 32 => [13, 188, 121], 33 => [229, 229, 16],
          34 => [36, 114, 200], 35 => [188, 63, 188], 36 => [17, 168, 205], 37 => [229, 229, 229],
          90 => [102, 102, 102], 91 => [241, 76, 76], 92 => [35, 209, 139], 93 => [245, 245, 67],
          94 => [59, 142, 234], 95 => [214, 112, 214], 96 => [41, 184, 219], 97 => [255, 255, 255]
        }
      end

      def basic_index_for_code(code)
        (code < 90) ? code - 30 : code - 90 + 8
      end
    end
  end
end
