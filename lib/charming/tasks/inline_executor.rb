# frozen_string_literal: true

module Charming
  module Tasks
    # InlineExecutor runs submitted tasks synchronously on the calling thread, pushing
    # the resulting TaskEvent directly into the runtime's *queue*. Used for testing and
    # for environments where spawning background threads is undesirable.
    class InlineExecutor
      # *queue* is the thread-safe Queue (typically `runtime.@task_queue`) into which
      # completed TaskEvents are pushed.
      def initialize(queue)
        @queue = queue
      end

      # Wraps *block* in a Task, invokes it immediately, and pushes the resulting
      # TaskEvent (value or error) onto the queue. Blocks that accept an argument
      # receive a Progress reporter (its events are queued before the completion event).
      # Returns nil.
      def submit(name, timeout: nil, &block)
        task = Task.new(name: name.to_sym, block: block, timeout: timeout)
        @queue << run(task)
        nil
      end

      # No-op: inline tasks have always finished by the time cancel could be called.
      def cancel(name)
      end

      # No-op stub for the shutdown contract; nothing to join since tasks run on the caller.
      def shutdown(timeout: 0.0)
      end

      private

      # Invokes the task's block and wraps the result (or raised exception) in a TaskEvent.
      def run(task)
        Events::TaskEvent.new(name: task.name, value: task.call(Progress.new(@queue, task.name)))
      rescue StandardError, ScriptError => e
        Events::TaskEvent.new(name: task.name, error: e)
      end
    end
  end
end
