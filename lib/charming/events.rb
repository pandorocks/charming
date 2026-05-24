# frozen_string_literal: true

module Charming
  KeyEvent = Data.define(:key, :char, :ctrl, :alt, :shift) do
    def initialize(key:, char: nil, ctrl: false, alt: false, shift: false)
      super
    end
  end

  ResizeEvent = Data.define(:width, :height)
end
