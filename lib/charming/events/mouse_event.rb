# frozen_string_literal: true

module Charming
  module Events
    # MOUSE_BUTTON_MAP encodes terminal mouse button codes to semantic symbols. The constant is frozen and private.
    MOUSE_BUTTON_MAP = {
      0 => :left, 1 => :middle, 2 => :right, 3 => :release,
      64 => :scroll_up, 65 => :scroll_down,
      66 => :scroll_up, 67 => :scroll_down
    }.freeze
    private_constant :MOUSE_BUTTON_MAP

    # MouseEvent represents a mouse input event. *button* encodes which button or action was triggered (left,
    # right, scroll), while *x* and *y* provide the cursor position. Modifier booleans (*ctrl*, *alt*, *shift*)
    # capture key state at the time of the event.
    MouseEvent = Data.define(:button, :x, :y, :ctrl, :alt, :shift) do
      def initialize(button:, x:, y:, ctrl: false, alt: false, shift: false)
        super
      end

      # Returns the semantic symbol for *button* — one of `left`, `right`, `scroll_up`, etc. or `:unknown`.
      def button_name
        MOUSE_BUTTON_MAP.fetch(button, :unknown)
      end

      # Returns `true` when the current event is a click (left, middle, or right button).
      def click?
        %i[left middle right].include?(button_name)
      end

      # Returns `true` when the button name maps to either direction of scroll.
      def scroll?
        %i[scroll_up scroll_down].include?(button_name)
      end

      # Returns `true` when the current event is a mouse release action.
      def release?
        button_name == :release
      end
    end
  end
end
