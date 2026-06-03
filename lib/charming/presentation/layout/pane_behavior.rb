# frozen_string_literal: true

module Charming
  module Layout
    # PaneBehavior holds the render-time options that control a Pane's
    # interaction with the focus ring and the embedded Viewport.
    class PaneBehavior
      attr_reader :focus, :scroll, :clip, :wrap

      def self.build(focus: false, scroll: false, clip: true, wrap: false)
        new(focus: focus, scroll: scroll, clip: clip, wrap: wrap)
      end

      def initialize(focus:, scroll:, clip:, wrap:)
        @focus, @scroll, @clip, @wrap = focus, scroll, clip, wrap
        freeze
      end

      def ==(other)
        other.is_a?(PaneBehavior) &&
          focus == other.focus && scroll == other.scroll &&
          clip == other.clip && wrap == other.wrap
      end
      alias_method :eql?, :==

      def hash
        [focus, scroll, clip, wrap].hash
      end

      def focusable?
        focus
      end

      def should_viewport?
        clip || scroll
      end
    end
  end
end
