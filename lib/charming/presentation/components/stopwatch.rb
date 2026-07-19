# frozen_string_literal: true

module Charming
  module Components
    # Stopwatch is a count-up display. Drive it from a controller timer: call
    # `tick` per interval; elapsed time accumulates only while running.
    class Stopwatch < Component
      attr_reader :elapsed, :label

      # *label* is an optional suffix shown after the time.
      def initialize(label: nil, theme: nil)
        super(theme: theme)
        @elapsed = 0
        @running = false
        @label = label
      end

      # Starts accumulating time. Returns self.
      def start
        @running = true
        self
      end

      # Pauses accumulation. Returns self.
      def stop
        @running = false
        self
      end

      # True while the stopwatch is accumulating time.
      def running?
        @running
      end

      # Adds *seconds* (default 1) when running; a no-op otherwise. Returns self.
      def tick(seconds = 1)
        @elapsed += seconds if running?
        self
      end

      # Stops and zeroes the elapsed time. Returns self.
      def reset
        @elapsed = 0
        @running = false
        self
      end

      # Renders the elapsed time (with the label appended when present).
      def render
        clock = TimeDisplay.clock(elapsed)
        label ? "#{clock} #{label}" : clock
      end
    end
  end
end
