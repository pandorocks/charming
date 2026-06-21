# frozen_string_literal: true

module Charming
  module Image
    # Terminal detects which terminal graphics protocol the host emulator supports, from
    # environment variables. It is the single detection seam: the rest of the image engine
    # dispatches on {protocol}. Injectable (`env:`) so specs never depend on the real terminal,
    # mirroring {Charming::Audio::System}.
    #
    # Phase 1 detects only the Kitty graphics protocol (Ghostty + Kitty). Other terminals report
    # `:none`, letting {Charming::Components::Image} fall back gracefully. Future protocols
    # (iTerm2, Sixel, half-block) slot in here without touching {Source} or the component.
    class Terminal
      # *env* is the environment hash probed for terminal identity (defaults to the process env).
      def initialize(env: ENV)
        @env = env
      end

      # The supported graphics protocol as a symbol: `:kitty` for Kitty/Ghostty, else `:none`.
      def protocol
        return :kitty if kitty?

        :none
      end

      # True when a real graphics protocol is available (i.e. {protocol} is not `:none`).
      def supports_graphics?
        protocol != :none
      end

      private

      # True when the host terminal speaks the Kitty graphics protocol (Kitty or Ghostty).
      def kitty?
        present?("KITTY_WINDOW_ID") ||
          term.match?(/kitty|ghostty/i) ||
          @env["TERM_PROGRAM"].to_s.casecmp?("ghostty") ||
          present?("GHOSTTY_RESOURCES_DIR")
      end

      # The `TERM` value as a string (never nil).
      def term
        @env["TERM"].to_s
      end

      # True when *key* is set to a non-empty value in the environment.
      def present?(key)
        !@env[key].to_s.empty?
      end
    end
  end
end
