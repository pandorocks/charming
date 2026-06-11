# frozen_string_literal: true

module Charming
  module Tasks
    # Cancelled is raised inside a task thread when the controller calls
    # `cancel_task(name)` or the task exceeds its `timeout:`. The task completes with
    # a TaskEvent whose error is this exception, so `on_task` handlers can detect it
    # via `event.error.is_a?(Charming::Tasks::Cancelled)`.
    class Cancelled < StandardError; end
  end
end
