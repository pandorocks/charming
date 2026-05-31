# frozen_string_literal: true

module Charming
  # KeyEvent represents a terminal key press parsed by the backend. *key* is the normalized semantic
  # action name (e.g., `:up`, `:down`, `:q`), while *char*, *ctrl*, *alt*, and *shift* capture raw
  # input details for custom bindings.
  KeyEvent = Data.define(:key, :char, :ctrl, :alt, :shift) do
    # Constructs a key event with the required *key* symbol, plus optional *char* string and modifier booleans.
    def initialize(key:, char: nil, ctrl: false, alt: false, shift: false)
      super(key: key.to_sym, char: char, ctrl: ctrl, alt: alt, shift: shift)
    end
  end
end
