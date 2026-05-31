# frozen_string_literal: true

module Charming
  # Screen represents the terminal viewport dimensions as a simple Data class.
  # The `width` and `height` values flow from the backend through the runtime
  # loop into every controller dispatch for layout calculations.
  Screen = Data.define(:width, :height)
end
