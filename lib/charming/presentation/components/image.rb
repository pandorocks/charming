# frozen_string_literal: true

module Charming
  module Components
    # Image displays a {Charming::Image::Source} inline in the terminal, sized to *rows*×*cols*
    # character cells. On a graphics-capable terminal (Phase 1: Ghostty/Kitty) it returns a block of
    # Unicode placeholder cells and registers the image's one-time out-of-band transmission; on other
    # terminals it returns *fallback* so layouts degrade gracefully.
    #
    # Like {Charming::Components::Audio}, the view itself is thin: the {Charming::Image::Source}
    # (held in `session`) owns the bytes and transmit state. The placeholder block is a normal
    # width-`cols` string that composes with `row`/`column`/`box` like any other view output.
    class Image < Component
      # *source* is the {Charming::Image::Source} to display. *rows*/*cols* size the image in
      # character cells. *fallback* is shown when the terminal lacks graphics support. *theme* is
      # forwarded to the view layer.
      def initialize(source:, rows:, cols:, fallback: "", theme: nil)
        super(theme: theme)
        @source = source
        @rows = rows
        @cols = cols
        @fallback = fallback
      end

      # Returns the placeholder block (registering the transmit once) on a graphics-capable terminal,
      # otherwise the fallback string.
      def render
        return @fallback.to_s unless @source.supports_graphics?

        unless @source.transmitted?
          Charming::Escape.register(@source.transmit(rows: @rows, cols: @cols))
          @source.mark_transmitted
        end
        @source.placement(rows: @rows, cols: @cols)
      end
    end
  end
end
