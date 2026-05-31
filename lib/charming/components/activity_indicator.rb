# frozen_string_literal: true

module Charming
  module Components
    # ActivityIndicator renders a color-gradient progress or loading indicator
    # as styled text. It produces a fixed-width row of characters whose colors
    # interpolate between two gradient endpoints (or cycle through a single
    # color). A label can be appended after the bar and an ellipsis that cycles
    # through frames, useful for "loading" state display. Call `tick` to advance
    # the frame counter, and call `render` to produce the styled output string.
    class ActivityIndicator < Component
      # Default character pool used for generating each position's character via stable hashing.
      DEFAULT_CHARS = "0123456789abcdefABCDEF~!@#$%^&*+=_".chars.freeze

      # The default two-color gradient applied across the bar width (red to cyan).
      # The cyan endpoint mirrors the Phosphor theme palette's "cyan" token so the bar
      # remains legible on Phosphor's dark navy background; gradient: accepts raw hex,
      # so callers using a different theme should pass their own endpoints.
      DEFAULT_GRADIENT = ["#ff0000", "#6FD0E3"].freeze

      # The default label color for ellipsis and text portions when no custom
      # label_style is provided.
      DEFAULT_LABEL_COLOR = "#cccccc"

      # Ellipsis frame sequence: four states cycle through "., "..", "...", and "" (empty).
      ELLIPSIS_FRAMES = [".", "..", "...", ""].freeze

      # Number of frames in the animation cycle before the indicator pattern repeats.
      FRAME_COUNT = 10

      # FNV-1a variant constants used by stable_hash for reproducible character selection per position.
      FNV_OFFSET = 2_166_136_261
      FNV_PRIME = 16_777_619
      FNV_MASK = 0xffffffff

      attr_reader :width, :label, :index, :seed, :chars, :gradient, :label_style

      # Initializes a new ActivityIndicator with configurable visual parameters.
      # width       — Display width of the gradient bar in characters (minimum 1). Default: 10.
      # label       — Optional text label shown adjacent to the indicator.
      # index       — Initial frame index for the ellipsis/frame animations. Default: 0.
      # seed        — Hash seed that determines which characters appear at each position.
      # chars       — Character pool to draw from (default is DEFAULT_CHARS).
      # gradient    — Two-element array of hex color strings ["#rrggbb", "#rrggbb"] for interpolation.
      # label_style — A Style object to use for rendering the label text; falls back to a gray foreground.
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

      # Advances the frame counter forward by +count+ steps, allowing the displayed pattern to change.
      # Accepts an integer count (converted via +to_i+). Returns self for chaining.
      def tick(count = 1)
        @index += count.to_i
        self
      end

      # Renders the activity indicator as a styled string. If a label was provided,
      # produces "bar ellipsis" alongside it; otherwise produces only the gradient bar.
      # Returns a formatted string suitable for terminal rendering.
      def render
        return indicator unless label

        "#{indicator} #{styled_label}#{styled_ellipsis}"
      end

      private

      # Renders the full gradient bar as an array of styled characters joined into a single string.
      # Each character at +position+ is selected by hashing together seed, frame, and position —
      # making the pattern stable across renders — then styled with the interpolated gradient color
      # at that position.
      def indicator
        Array.new(width) { |position| styled_char(position) }.join
      end

      # Selects a character for the bar at the given +position+, styles it with the gradient color
      # interpolated for that position, and returns the result as a formatted string via +render+.
      def styled_char(position)
        style.foreground(color_at(position)).render(char_at(position))
      end

      # Chooses a character from self.chars by hashing seed:frame:position together with a stable
      # FNV-1a hash. The resulting index is modulated against the character pool length, ensuring
      # reproducible output across renders.
      def char_at(position)
        chars.fetch(stable_hash("#{seed}:#{frame}:#{position}") % chars.length)
      end

      # Renders the label text in its own style (or fallback gray color) via a Style renderer call.
      def styled_label
        label_style_or_default.render(label.to_s)
      end

      # Renders an ellipsis frame (".", "..", "...", or empty) based on (index / 4) mod 4, styled with the label style.
      def styled_ellipsis
        label_style_or_default.render(ellipsis_frame)
      end

      # Returns the current ellipsis frame string: one of ".", "..", "...", "". Cycles through four frames per tick.
      def ellipsis_frame
        ELLIPSIS_FRAMES.fetch((index / 4) % ELLIPSIS_FRAMES.length)
      end

      # Returns the label style if set, otherwise produces a gray foreground style for fallback rendering.
      def label_style_or_default
        label_style || style.foreground(DEFAULT_LABEL_COLOR)
      end

      # Interpolates between gradient[0] and gradient[1] at the fractional +position+ (0.0 to 1.0).
      # Returns the first gradient color if width is 1; otherwise returns a blended hex string based on position.
      def color_at(position)
        return gradient.first unless width > 1

        blend(gradient.first, gradient.last, position / (width - 1).to_f)
      end

      # Blends two hex colors by interpolating their red/green/blue components at fractional +amount+.
      # Accepts strings like "#ff0000" and produces a new "#rrggbb" string.
      def blend(start_hex, end_hex, amount)
        start_rgb = rgb(start_hex)
        end_rgb = rgb(end_hex)
        mixed = start_rgb.zip(end_rgb).map { |from, to| (from + ((to - from) * amount)).round }
        "#%02x%02x%02x" % mixed
      end

      # Decomposes a hex color string ("#rrggbb") into an array of three integers [r, g, b].
      def rgb(hex)
        value = hex.to_s.delete_prefix("#")
        raise ArgumentError, "gradient colors must be #rrggbb" unless value.match?(/\A[0-9a-fA-F]{6}\z/)

        [value[0..1], value[2..3], value[4..5]].map { |part| part.to_i(16) }
      end

      # Advances the animation frame counter, wrapping around after +FRAME_COUNT+ (10) steps.
      def frame
        index % FRAME_COUNT
      end

      # Produces a deterministic integer hash from the input string using FNV-1a hashing, ensuring the same
      # characters appear at the same positions across multiple renderings of this indicator.
      def stable_hash(value)
        value.bytes.reduce(FNV_OFFSET) do |hash, byte|
          ((hash ^ byte) * FNV_PRIME) & FNV_MASK
        end
      end
    end
  end
end
