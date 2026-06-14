# frozen_string_literal: true

module Charming
  # Audio provides simple, cross-platform sound playback by shelling out to a system
  # audio binary. The engine lives in {Player}; {System} is the swappable OS adapter.
  module Audio
    # Player plays a single sound file by spawning a system audio binary, and exposes
    # `stop`/`playing?`/`wait` to manage the child process. It never blocks the event
    # loop on its own — call {play} for fire-and-forget playback, or drive it from a
    # controller `run_task` (spawn + {wait}, with an `ensure player.stop`) to get a
    # completion event and reliable teardown when the app quits.
    #
    # A backend binary is resolved on first use, in priority order: `ffplay` (from
    # ffmpeg) on every platform, then OS-native players (`afplay` on macOS; `paplay`,
    # `mpg123`, `aplay` on Linux). {Unavailable} is raised when none are installed.
    class Player
      # Raised by {play} when no supported audio backend is found on `PATH`.
      class Unavailable < Charming::Error; end

      # Candidate backends in resolution order. `:os` is `:any`, `:macos`, or `:linux`;
      # `:args` are inserted before the file path in the spawned command.
      BACKENDS = [
        {command: "ffplay", os: :any, args: ["-nodisp", "-autoexit", "-loglevel", "quiet"]},
        {command: "afplay", os: :macos, args: []},
        {command: "paplay", os: :linux, args: []},
        {command: "mpg123", os: :linux, args: ["-q"]},
        {command: "aplay", os: :linux, args: ["-q"]}
      ].freeze

      # *system* is the OS adapter used to probe `PATH` and spawn/track the player
      # process. The default talks to the real OS; specs inject a fake.
      def initialize(system: System.new)
        @system = system
        @pid = nil
      end

      # Plays the sound file at *path*, stopping any sound already in progress first.
      # Spawns the resolved backend and returns the child PID. Raises {Unavailable}
      # when no backend binary is installed for this platform.
      def play(path)
        backend = resolve_backend!
        stop if playing?
        @pid = @system.spawn([backend[:command], *backend[:args], path.to_s])
      end

      # Stops the current sound (if any), terminating and reaping the child process.
      # Safe to call when nothing is playing.
      def stop
        return unless @pid

        @system.terminate(@pid)
        @system.wait(@pid)
        @pid = nil
      end

      # True while a spawned sound is still playing.
      def playing?
        !@pid.nil? && @system.alive?(@pid)
      end

      # Blocks until the current sound finishes, then clears it. Intended for use inside
      # a background `run_task`. If the task thread is killed mid-wait (e.g. on app
      # shutdown), `@pid` is left intact so an `ensure player.stop` can reap the child.
      def wait
        return unless @pid

        @system.wait(@pid)
        @pid = nil
      end

      # True when a backend binary is installed for this platform. Lets callers degrade
      # gracefully (e.g. skip a chime) instead of rescuing {Unavailable}.
      def available?
        !backend.nil?
      end

      private

      # Returns the resolved backend or raises {Unavailable} listing what was searched.
      def resolve_backend!
        backend || raise(Unavailable, "no audio player found on PATH (looked for: #{searched.join(", ")})")
      end

      # The first supported, installed backend for this platform, or nil. Memoized once found.
      def backend
        @backend ||= BACKENDS.find { |candidate| supported?(candidate) && @system.which?(candidate[:command]) }
      end

      # The command names that apply to this platform, in order (for error messages).
      def searched
        BACKENDS.select { |candidate| supported?(candidate) }.map { |candidate| candidate[:command] }
      end

      # True when *candidate* targets this platform.
      def supported?(candidate)
        case candidate[:os]
        when :any then true
        when :macos then @system.macos?
        when :linux then @system.linux?
        end
      end
    end
  end
end
