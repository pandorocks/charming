# frozen_string_literal: true

module Charming
  module Components
    # Audio is a one-line playback-status indicator for a {Charming::Audio::Player}. It
    # reads the player's `playing?` state and renders a play/stop glyph with an optional
    # *label*; pair it with a controller timer (or `on_task` re-render) to keep it live.
    #
    # Note: this view component (`Charming::Components::Audio`) is distinct from the
    # playback engine namespace (`Charming::Audio`) — the component only displays state,
    # the engine spawns the sound.
    class Audio < Component
      # *player* is the {Charming::Audio::Player} whose state is shown. *label* is an
      # optional suffix (e.g. the track name) appended after the glyph. *theme* is the
      # active theme, forwarded to the view layer.
      def initialize(player:, label: nil, theme: nil)
        super(theme: theme)
        @player = player
        @label = label
      end

      # Renders `▶`/`■` for playing/stopped, followed by the label when present.
      def render
        glyph = @player.playing? ? "▶" : "■"
        return glyph unless @label

        "#{glyph} #{@label}"
      end
    end
  end
end
