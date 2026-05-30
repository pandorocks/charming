# frozen_string_literal: true

module Charming
  module Components
    class Spinner < Component
      DEFAULT_FRAMES = ["-", "\\", "|", "/"].freeze

      attr_reader :frames, :index, :label

      def initialize(frames: DEFAULT_FRAMES, index: 0, label: nil)
        super()
        raise ArgumentError, "frames cannot be empty" if frames.empty?

        @frames = frames
        @index = index
        @label = label
      end

      def tick
        @index = (index + 1) % frames.length
        self
      end

      def render
        return frame unless label

        "#{frame} #{label}"
      end

      private

      def frame
        frames.fetch(index % frames.length)
      end
    end
  end
end
