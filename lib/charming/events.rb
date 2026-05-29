# frozen_string_literal: true

module Charming
  KeyEvent = Data.define(:key, :char, :ctrl, :alt, :shift) do
    def initialize(key:, char: nil, ctrl: false, alt: false, shift: false)
      super
    end
  end

  ResizeEvent = Data.define(:width, :height)

  MouseEvent = Data.define(:button, :x, :y, :ctrl, :alt, :shift) do
    BUTTON_MAP = {
      0 => :left, 1 => :middle, 2 => :right, 3 => :release,
      64 => :scroll_up, 65 => :scroll_down,
      66 => :scroll_up, 67 => :scroll_down
    }.freeze

    def initialize(button:, x:, y:, ctrl: false, alt: false, shift: false)
      super
    end

    def button_name
      BUTTON_MAP.fetch(button, :unknown)
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

  TimerEvent = Data.define(:name, :now)

  def self.key_of(event)
    event.respond_to?(:key) ? event.key : event
  end
end
