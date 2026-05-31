# frozen_string_literal: true

module Charming
  module Events
    # ResizeEvent represents a terminal window resize. *width* and *height* carry the new terminal dimensions
    # in screen cells, replacing the previous Screen dimensions for all subsequent rendering.
    ResizeEvent = Data.define(:width, :height)
  end
end
