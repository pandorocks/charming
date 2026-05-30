# frozen_string_literal: true

module Charming
  MOUSE_BUTTON_MAP = {
    0 => :left, 1 => :middle, 2 => :right, 3 => :release,
    64 => :scroll_up, 65 => :scroll_down,
    66 => :scroll_up, 67 => :scroll_down
  }.freeze
  private_constant :MOUSE_BUTTON_MAP

  MouseEvent = Data.define(:button, :x, :y, :ctrl, :alt, :shift) do
    def initialize(button:, x:, y:, ctrl: false, alt: false, shift: false)
      super
    end

    def button_name
      MOUSE_BUTTON_MAP.fetch(button, :unknown)
    end

    def click?
      %i[left middle right].include?(button_name)
    end

    def scroll?
      %i[scroll_up scroll_down].include?(button_name)
    end

    def release?
      button_name == :release
    end
  end
end
