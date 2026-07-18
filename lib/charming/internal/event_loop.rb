# frozen_string_literal: true

module Charming
  module Internal
    # EventLoop pumps events for a Charming runtime: it delivers the next due
    # event — completed background tasks first, then due timers, then terminal
    # input (with optional held-key coalescing) — to the block passed to {#run},
    # until the block returns :quit, the interrupt check trips, or a test
    # backend runs out of events. It knows nothing about controllers, routes,
    # or rendering; deciding what an event *means* belongs to its caller.
    class EventLoop
      DEFAULT_READ_TIMEOUT = 0.05

      # *timer_bindings* is the list of controller timer bindings (each
      # responding to `name` and `interval`) to schedule. *interrupted* is a
      # callable checked every iteration so a signal handler can stop the loop.
      def initialize(backend:, clock:, task_queue:, timer_bindings: [], coalesce_input: false, interrupted: -> { false })
        @backend = backend
        @clock = clock
        @task_queue = task_queue
        @coalesce_input = coalesce_input
        @interrupted = interrupted
        @timers = build_timers(timer_bindings)
        @pending_event = nil
      end

      # Pumps events, yielding each to the caller. Stops when the block returns
      # :quit, when the interrupt check returns true, or when a test backend is
      # exhausted. Closes the task queue on the way out so producer threads
      # can't block on a loop that is no longer draining them.
      def run
        loop do
          break if @interrupted.call

          event = next_event
          unless event
            break if backend_exhausted?
            next
          end
          break if yield(event) == :quit
        end
      ensure
        @task_queue.close
      end

      # Replaces the scheduled timers — called when navigation lands on a
      # controller with different timer bindings.
      def reset_timers(timer_bindings)
        @timers = build_timers(timer_bindings)
      end

      private

      # The next due event in priority order: task results, then timers, then input.
      def next_event
        next_task_event || next_timer_event || next_input_event
      end

      # Pops a task event from the thread-safe queue if one is available.
      # Non-blocking — returns nil immediately when the queue is empty.
      def next_task_event
        @task_queue.pop(true)
      rescue ThreadError
        nil
      end

      # Returns a TimerEvent for the first due timer and advances its next fire
      # time. Returns nil if no timers are ready or registered.
      def next_timer_event
        timer = due_timer
        return unless timer

        now = clock_now
        timer[:next_at] = now + timer.fetch(:binding).interval
        Events::TimerEvent.new(name: timer.fetch(:binding).name, now: now)
      end

      # Reads the next input event, consuming a stashed event first, then
      # collapsing any auto-repeat burst behind it.
      def next_input_event
        event = @pending_event
        @pending_event = nil
        event ||= @backend.read_event(timeout: read_timeout)
        return event unless event && @coalesce_input

        coalesce(event)
      end

      # Collapses a run of identical key events — the flood the terminal emits while
      # a key is held down — into a single delivered event, so holding a key can't
      # queue a backlog that keeps acting after release. The first non-matching event
      # encountered is stashed for the next loop iteration, so distinct keys and
      # non-key events (resize/paste/mouse) are never lost. Only KeyEvents are
      # coalesced; everything else passes straight through.
      def coalesce(event)
        return event unless event.is_a?(Events::KeyEvent)

        # Only read while input is *immediately* available, so the drain never blocks
        # on an empty buffer (input_pending? is a true 0s check).
        while @backend.input_pending?
          nxt = @backend.read_event(timeout: 0)
          break unless nxt
          next if nxt == event # identical auto-repeat — discard the older one, keep draining

          @pending_event = nxt
          break
        end
        event
      end

      # Computes how long to block waiting for input based on when the next timer
      # is due, clamped between 0 and DEFAULT_READ_TIMEOUT. Returns DEFAULT when
      # no timers exist.
      def read_timeout
        return DEFAULT_READ_TIMEOUT if @timers.empty?

        next_at = @timers.map { |timer| timer.fetch(:next_at) }.min
        (next_at - clock_now).clamp(0, DEFAULT_READ_TIMEOUT)
      end

      # Returns the timer due at or before now with the earliest fire time.
      def due_timer
        now = clock_now
        @timers.select { |timer| timer.fetch(:next_at) <= now }.min_by { |timer| timer.fetch(:next_at) }
      end

      # Builds timer states from bindings, scheduling each one interval from now.
      def build_timers(timer_bindings)
        now = clock_now
        timer_bindings.map { |binding| {binding: binding, next_at: now + binding.interval} }
      end

      # True when the backend reports it has no more events to deliver (test
      # backends only — the TTY backend never exhausts). Prevents the loop from
      # spinning forever in tests that forget a trailing quit event.
      def backend_exhausted?
        @backend.respond_to?(:exhausted?) && @backend.exhausted?
      end

      # Returns current clock time.
      def clock_now
        @clock.call
      end
    end
  end
end
