# frozen_string_literal: true

module Charming
  module Components
    # Spinner is a simple rotating-frame indicator. The component cycles through a list of
    # frames on each `tick`; pair it with a controller timer to drive animation. An optional
    # *label* is appended after the current frame on each render.
    class Spinner < Component
      # The default frame set: a 4-frame ASCII spinner.
      DEFAULT_FRAMES = ["-", "\\", "|", "/"].freeze

      # The current frame list, frame index, and optional label string.
      attr_reader :frames, :index, :label

      # *frames* defaults to DEFAULT_FRAMES but may be replaced with any array of frame strings.
      # *index* is the starting frame index. *label* is an optional suffix shown after the frame.
      def initialize(frames: DEFAULT_FRAMES, index: 0, label: nil)
        super()
        raise ArgumentError, "frames cannot be empty" if frames.empty?

        @frames = frames
        @index = index
        @label = label
      end

      # Advances the frame index by one position, wrapping around. Returns self for chaining.
      def tick
        @index = (index + 1) % frames.length
        self
      end

      # Renders the current frame, optionally followed by the label and a space.
      def render
        return frame unless label

        "#{frame} #{label}"
      end

      private

      # Returns the current frame string (with index modulo frame count to be safe).
      def frame
        frames.fetch(index % frames.length)
      end
    end
  end
end
