# frozen_string_literal: true

module Charming
  module UI
    # Background tracks whether the terminal has a dark or light background so
    # adaptive colors and the markdown :auto style can pick the readable variant.
    #
    # The runtime feeds a definitive answer from an OSC 11 query when the
    # terminal replies to one (see TTYBackend#query_background_color); otherwise
    # detection falls back to the COLORFGBG convention and finally assumes dark —
    # the overwhelmingly common terminal default. `Background.assume = :light`
    # overrides everything (useful in tests and for user preference).
    module Background
      MODES = %i[dark light].freeze

      # ITU-R BT.601 luma threshold on 8-bit channels: below this is "dark".
      LUMA_THRESHOLD = 128

      module_function

      # True when the terminal background is dark (the assumed mode, or detection).
      def dark?
        (@assumed || detect(ENV)) == :dark
      end

      # Overrides detection with :dark or :light; nil returns to auto-detection.
      def assume=(value)
        raise ArgumentError, "unknown background: #{value.inspect}" if value && !MODES.include?(value)

        @assumed = value
      end

      # Detects the background from an environment hash via the COLORFGBG
      # convention ("<fg>;<bg>", where bg 7 or 15 means a light background).
      # Defaults to :dark when the environment says nothing.
      def detect(env)
        bg_index = env["COLORFGBG"].to_s.split(";").last
        %w[7 15].include?(bg_index) ? :light : :dark
      end

      # Classifies an 8-bit RGB triple as :dark or :light by luma.
      def classify(red, green, blue)
        luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        (luma < LUMA_THRESHOLD) ? :dark : :light
      end

      # Parses an OSC 11 reply ("\e]11;rgb:RRRR/GGGG/BBBB" + BEL or ST) and
      # classifies the reported color. Returns nil for anything unparseable.
      def parse_osc11(reply)
        match = reply.to_s.match(%r{\e\]11;rgb:(\h{2,4})/(\h{2,4})/(\h{2,4})})
        return unless match

        red, green, blue = match.captures.map { |channel| channel[0, 2].to_i(16) }
        classify(red, green, blue)
      end
    end
  end
end
