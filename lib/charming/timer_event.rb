# frozen_string_literal: true

module Charming
  # TimerEvent represents a timed dispatch from the runtime loop. *name* is the declared timer identifier;
  # *now* is the monotonically rising clock value at emission for throttle comparisons.
  TimerEvent = Data.define(:name, :now)
end
