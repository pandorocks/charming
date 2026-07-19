# frozen_string_literal: true

module Charming
  class Controller
    # Timer control helpers mixed into Controller. Controllers are ephemeral, so
    # starting and stopping named timers is delegated to the runtime-owned
    # TimerControl exposed on the application (a null object outside a runtime).
    module Timers
      # Schedules the named declared timer. Idempotent while the timer is running.
      def start_timer(name)
        application.timer_control.start(name)
      end

      # Unschedules the named timer. Idempotent when it is not running.
      def stop_timer(name)
        application.timer_control.stop(name)
      end

      # True while the named timer is scheduled.
      def timer_running?(name)
        application.timer_control.running?(name)
      end
    end
  end
end
