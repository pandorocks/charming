# frozen_string_literal: true

require "digest"

module Charming
  module Image
    # Source owns an image's bytes, its stable id, and its transmit state — the "engine" half of the
    # image feature, analogous to {Charming::Audio::Player}. Keep it in `session` (built once) rather
    # than rebuilt per render, so {transmitted?} reliably gates the one-time transmission.
    #
    # It dispatches to the active {Protocol} (chosen by its {Terminal}) to build the out-of-band
    # {Transmit} and the in-frame placeholder block, and is a no-op on terminals without graphics
    # support, letting {Charming::Components::Image} fall back gracefully.
    class Source
      # *path* or *data* supplies the (PNG) bytes — exactly one is required. *id* overrides the
      # derived image id. *terminal* is the protocol-detection seam (injectable for specs).
      def initialize(path: nil, data: nil, id: nil, terminal: Terminal.new)
        raise ArgumentError, "provide either path: or data:" unless path || data

        @path = path
        @data = data
        @id = id
        @terminal = terminal
        @transmitted = false
      end

      # The protocol-detection seam, exposed so the component can ask {supports_graphics?}.
      attr_reader :terminal

      # The stable 32-bit image id (kept within 24 bits so the placeholder foreground colour fully
      # encodes it). Derived from a digest of the bytes unless an explicit id was given.
      def image_id
        @image_id ||= @id || derive_id
      end

      # True when the host terminal supports a graphics protocol.
      def supports_graphics?
        @terminal.supports_graphics?
      end

      # Builds the out-of-band {Transmit} for a *rows*×*cols* placement, or nil when graphics are
      # unsupported. The {Runtime} flushes it to the backend; {Charming::Escape.register} collects it.
      def transmit(rows:, cols:)
        return unless protocol

        Transmit.new(image_id: image_id, payload: protocol.transmit(image_id: image_id, png_bytes: bytes, rows: rows, cols: cols))
      end

      # The in-frame placeholder block sized *rows*×*cols*, or "" when graphics are unsupported.
      def placement(rows:, cols:)
        return "" unless protocol

        protocol.placeholder_block(image_id: image_id, rows: rows, cols: cols)
      end

      # Builds the out-of-band {Transmit} that frees the image from terminal memory, or nil when
      # graphics are unsupported. Re-arms {transmitted?} so a later render retransmits. Callers
      # evicting an image register this the same way as {transmit}.
      def release
        return unless protocol

        @transmitted = false
        Transmit.new(image_id: image_id, payload: protocol.delete(image_id: image_id))
      end

      # True once {mark_transmitted} has recorded that the image was sent to the terminal.
      def transmitted?
        @transmitted
      end

      # Records that the image has been transmitted, so it is not re-sent on later renders.
      def mark_transmitted
        @transmitted = true
      end

      private

      # The encoder module for the detected protocol, or nil when none applies.
      def protocol
        @protocol = Protocol.for(@terminal.protocol) unless defined?(@protocol)
        @protocol
      end

      # The raw image bytes, read once from *path* (binary) or taken from *data*.
      def bytes
        @bytes ||= @data || File.binread(@path)
      end

      # A stable, nonzero 24-bit id derived from the image bytes.
      def derive_id
        (Digest::SHA256.digest(bytes).unpack1("N") % 0xFFFFFE) + 1
      end
    end
  end
end
