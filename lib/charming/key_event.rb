# frozen_string_literal: true

module Charming
  # KeyEvent represents a terminal key press parsed by the backend. *key* is the semantic action name
  # (e.g., `:up`, `:down`), while *char*, *ctrl*, *alt*, and *shift* capture raw input details for custom bindings.
  KeyEvent = Data.define(:key, :char, :ctrl, :alt, :shift) do
    # Constructs a key event with the required *key* symbol, plus optional *char* string and modifier booleans.
    def initialize(key:, char: nil, ctrl: false, alt: false, shift: false)
      super
    end
  end
end
