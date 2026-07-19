# frozen_string_literal: true

module DemoApp
  module Physics
    # Draws the spring demo: a ball on a dotted track, a readout of the spring's
    # position, and whether the animation timer is currently running.
    class ShowView < Charming::View
      TRACK_WIDTH = 44

      def render
        column(
          text("Spring", style: theme.title),
          track,
          readout,
          text("Press b to bounce the ball.", style: theme.muted),
          gap: 1
        )
      end

      private

      def physics
        assigns.fetch(:physics)
      end

      def running
        assigns.fetch(:running)
      end

      def track
        cells = Array.new(TRACK_WIDTH) { "\u{00b7}" }
        cells[physics.x.round.clamp(0, TRACK_WIDTH - 1)] = "\u{25cf}"
        text cells.join, style: theme.info
      end

      def readout
        state = running ? "spring running" : "spring settled"
        text "x: #{format("%.1f", physics.x)}  #{state}", style: theme.text
      end
    end
  end
end
