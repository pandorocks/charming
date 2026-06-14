# frozen_string_literal: true

module Charming
  module Audio
    # System is the OS adapter the {Player} uses to locate and control audio-player
    # processes. It wraps Ruby's `Process`/`ENV`/`RbConfig` so specs can substitute a
    # fake collaborator and never shell out, touch the real process table, or play sound.
    class System
      # *host_os* identifies the platform (defaults to the running Ruby's). *path* is the
      # `PATH` string searched by {which?} (defaults to the process environment).
      def initialize(host_os: RbConfig::CONFIG["host_os"], path: ENV["PATH"])
        @host_os = host_os.to_s
        @path = path.to_s
      end

      # True on macOS.
      def macos?
        @host_os.match?(/darwin/i)
      end

      # True on Linux.
      def linux?
        @host_os.match?(/linux/i)
      end

      # True when *command* resolves to an executable file on `PATH`.
      def which?(command)
        path_dirs.any? do |dir|
          candidate = File.join(dir, command)
          File.file?(candidate) && File.executable?(candidate)
        end
      end

      # Spawns *argv* (an array) detached from the terminal, discarding the child's
      # stdout/stderr, and returns the child PID.
      def spawn(argv)
        Process.spawn(*argv, out: File::NULL, err: File::NULL)
      end

      # Sends `SIGTERM` to *pid*, ignoring a process that has already exited.
      def terminate(pid)
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        nil
      end

      # True while *pid* is still running. Reaps the child (non-blocking) once it exits.
      def alive?(pid)
        Process.waitpid(pid, Process::WNOHANG).nil?
      rescue Errno::ECHILD, Errno::ESRCH
        false
      end

      # Blocks until *pid* exits, then reaps it. No-op when the child is already gone.
      def wait(pid)
        Process.waitpid(pid)
      rescue Errno::ECHILD, Errno::ESRCH
        nil
      end

      private

      # Returns the directories on `PATH`.
      def path_dirs
        @path.split(File::PATH_SEPARATOR)
      end
    end
  end
end
