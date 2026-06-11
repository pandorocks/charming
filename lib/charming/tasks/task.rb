# frozen_string_literal: true

require "timeout"

module Charming
  module Tasks
    # Task is the unit of work submitted to a task executor. It pairs a *name* (used by
    # `on_task` handlers to route the result) with a *block* to invoke on the executor,
    # plus an optional *timeout* in seconds.
    Task = Data.define(:name, :block, :timeout) do
      def initialize(name:, block:, timeout: nil)
        super
      end

      # Invokes the task's block, passing *progress* when the block accepts an argument.
      # Enforces the timeout (raising Tasks::Cancelled) when one was configured.
      def call(progress = nil)
        return invoke(progress) unless timeout

        Timeout.timeout(timeout, Cancelled, "task #{name} timed out after #{timeout}s") do
          invoke(progress)
        end
      end

      private

      def invoke(progress)
        block.arity.zero? ? block.call : block.call(progress)
      end
    end
  end
end
