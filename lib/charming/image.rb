# frozen_string_literal: true

module Charming
  # Image provides terminal image display. Unlike {Charming::Audio} (which spawns an out-of-band
  # process and never touches the TTY), images must be written *into* the terminal — but the
  # framework's renderer is line-based and width-measured, and would shred raw image escape
  # sequences. So images use the Kitty graphics protocol's *Unicode placeholders*: the image bytes
  # are transmitted once out-of-band (see {Charming::Image::Transmit} and the {Runtime}'s graphics
  # flush), then placed by printing ordinary width-1 placeholder cells that ride the normal frame
  # pipeline (see {Charming::Image::Protocol::Kitty}).
  #
  # The engine here ({Source}, {Terminal}, {Protocol}) mirrors {Charming::Audio}'s split; the view
  # is {Charming::Components::Image}. Terminal support is detected via {Terminal}; Phase 1 targets
  # Ghostty/Kitty and degrades to a fallback string elsewhere.
  #
  # Image transmissions ride the shared out-of-band {Charming::Escape} channel: {Transmit} responds
  # to `#payload`, so the component registers it via `Charming::Escape.register` and the {Runtime}
  # flushes it before the frame.
  module Image
  end
end
