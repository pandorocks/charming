# frozen_string_literal: true

module Charming
  module Components
    # Timer is a countdown display. Drive it from a controller timer: call
    # `tick` per interval and check `expired?` to act when time runs out.
    class Timer < Component
      attr_reader :duration, :remaining, :label

      # *duration* is the countdown length in seconds. *label* is an optional
      # suffix shown after the time.
      def initialize(duration:, label: nil, theme: nil)
        super(theme: theme)
        @duration = [duration.to_i, 0].max
        @remaining = @duration
        @label = label
      end

      # Counts down by *seconds* (default 1), clamping at zero. Returns self.
      def tick(seconds = 1)
        @remaining = [@remaining - seconds.to_i, 0].max
        self
      end

      # True once the countdown has reached zero.
      def expired?
        remaining.zero?
      end

      # Restores the full duration. Returns self.
      def reset
        @remaining = duration
        self
      end

      # Renders the remaining time (with the label appended when present).
      def render
        clock = TimeDisplay.clock(remaining)
        label ? "#{clock} #{label}" : clock
      end
    end
  end
end
