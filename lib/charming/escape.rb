# frozen_string_literal: true

module Charming
  # Escape is the out-of-band terminal channel: escape sequences written straight to the terminal,
  # *before* each frame, bypassing the line-based renderer (which measures width and would shred raw
  # control sequences). It is the shared substrate for several primitives — image transmissions
  # ({Charming::Image::Transmit}), clipboard writes, desktop notifications, and the window title.
  #
  # Sequences are gathered during an event's dispatch via a thread-local collector ({collecting} /
  # {register}) and attached to the {Response}; the {Runtime} flushes them through
  # `backend.write_escape`. Any object that responds to `#payload` (a string) can ride the channel;
  # the builders here return {Sequence} value objects and sanitize interpolated text so user content
  # can't break out of the sequence.
  module Escape
    # A single out-of-band sequence. *payload* is the literal escape string written to the terminal.
    Sequence = Data.define(:payload)

    # Thread-local key under which the active collection bucket is stored.
    BUCKET_KEY = :charming_escape_bucket

    class << self
      # Runs *block* with a fresh collection bucket active and returns the bucket — the {Sequence}s
      # registered via {register} during the block. The block's own return value is ignored (capture
      # it via a closure). Nesting is supported: an inner collection shadows the outer.
      def collecting
        previous = Thread.current[BUCKET_KEY]
        bucket = []
        Thread.current[BUCKET_KEY] = bucket
        yield
        bucket
      ensure
        Thread.current[BUCKET_KEY] = previous
      end

      # Registers *sequence* with the active collection bucket so it is flushed to the backend. A
      # no-op (outside a collection, or when *sequence* is nil) so callers can register freely.
      def register(sequence)
        return sequence unless sequence

        Thread.current[BUCKET_KEY]&.push(sequence)
        sequence
      end

      # Builds an OSC 52 clipboard-write sequence setting the *target* selection (`"c"` clipboard,
      # `"p"` primary) to *text*. The text is base64-encoded, so any bytes are safe.
      def clipboard(text, target: "c")
        Sequence.new(payload: "\e]52;#{target};#{[text.to_s].pack("m0")}\a")
      end

      # Builds a desktop-notification sequence: OSC 777 (`title` + `body`) when a *title* is given,
      # else OSC 9 (body only) — the broadly supported baseline (Ghostty, iTerm2, Kitty).
      def notification(body, title: nil)
        payload =
          if title
            "\e]777;notify;#{sanitize(title)};#{sanitize(body)}\e\\"
          else
            "\e]9;#{sanitize(body)}\a"
          end
        Sequence.new(payload: payload)
      end

      # Builds a terminal-bell sequence (BEL).
      def bell
        Sequence.new(payload: "\a")
      end

      # Builds an OSC 0 sequence setting the terminal window (and icon) title to *text*.
      def title(text)
        Sequence.new(payload: "\e]0;#{sanitize(text)}\a")
      end

      private

      # Strips C0 control characters (incl. ESC and BEL) so interpolated user text can't terminate
      # or inject into the surrounding escape sequence.
      def sanitize(text)
        text.to_s.gsub(/[\x00-\x1f\x7f]/, "")
      end
    end
  end
end
