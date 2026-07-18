# frozen_string_literal: true

module Charming
  module Components
    # TimeDisplay formats whole-second durations as clock strings: "mm:ss", or
    # "h:mm:ss" once an hour is reached. Shared by Timer and Stopwatch.
    module TimeDisplay
      module_function

      def clock(total_seconds)
        seconds = [total_seconds.to_i, 0].max
        hours, remainder = seconds.divmod(3600)
        minutes, secs = remainder.divmod(60)
        return format("%d:%02d:%02d", hours, minutes, secs) if hours.positive?

        format("%02d:%02d", minutes, secs)
      end
    end
  end
end
