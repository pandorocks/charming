# frozen_string_literal: true

module Charming
  module Internal
    # TimerControl is the runtime-injected surface that lets ephemeral controllers
    # start and stop the EventLoop's scheduled timers by name (the same pattern as
    # Application#task_executor). *bindings* is a callable returning the current
    # route's timer bindings, so navigation needs no re-wiring.
    class TimerControl
      def initialize(event_loop:, bindings:)
        @event_loop = event_loop
        @bindings = bindings
      end

      # Schedules the named declared timer on the event loop.
      def start(name)
        binding = @bindings.call[name.to_sym]
        raise ArgumentError, "unknown timer #{name.to_sym.inspect}" unless binding

        @event_loop.start_timer(binding)
      end

      # Unschedules the named timer.
      def stop(name)
        @event_loop.stop_timer(name.to_sym)
      end

      # True while the named timer is scheduled.
      def running?(name)
        @event_loop.timer_running?(name.to_sym)
      end

      # Null is the default control for applications running outside a Runtime
      # (unit specs, console): starts and stops are no-ops.
      class Null
        def start(name)
        end

        def stop(name)
        end

        def running?(name)
          false
        end
      end
    end
  end
end
