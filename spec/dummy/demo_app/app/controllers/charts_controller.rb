# frozen_string_literal: true

module DemoApp
  # Demonstrates the pure-text data-viz components: Sparkline and Chart (braille line + block bars).
  class ChartsController < ApplicationController
    SERIES = [3, 5, 4, 8, 7, 9, 6, 11, 10, 13, 12, 15, 14, 18, 16, 19].freeze

    def show
      render :show, series: SERIES, palette: command_palette
    end
  end
end
