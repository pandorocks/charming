# frozen_string_literal: true

module Charming
  module Tasks
    # Task is the unit of work submitted to a task executor. It pairs a *name* (used by
    # `on_task` handlers to route the result) with a *block* to invoke on the executor.
    Task = Data.define(:name, :block) do
      # Invokes the task's block in the executor's thread and returns its value (or raises).
      def call = block.call
    end
  end
end
