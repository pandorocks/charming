# frozen_string_literal: true

module Charming
  module UI
    # AdaptiveColor is a color value that resolves to its light or dark variant
    # at render time, based on the detected terminal background. Build one with
    # `UI.adaptive(light:, dark:)` and use it anywhere a color is accepted.
    class AdaptiveColor
      def initialize(light:, dark:)
        @light = light
        @dark = dark
      end

      # The variant readable on the current terminal background.
      def resolve
        Background.dark? ? @dark : @light
      end
    end
  end
end
