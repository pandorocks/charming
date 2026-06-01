# frozen_string_literal: true

module Charming
  module Tasks
    # ThreadedExecutor runs submitted tasks on background Ruby threads. Each submission
    # creates a new thread that invokes the block and pushes the resulting TaskEvent
    # onto the shared *queue*. Threads are tracked so `shutdown` can wait (or kill)
    # in-flight work.
    class ThreadedExecutor
      # *queue* is the thread-safe Queue (typically `runtime.@task_queue`) into which
      # completed TaskEvents are pushed.
      def initialize(queue)
        @queue = queue
        @threads = []
        @mutex = Mutex.new
      end

      # Wraps *block* in a Task and spawns a new thread to invoke it. The thread's
      # return value (or rescued exception) is pushed onto the queue as a TaskEvent.
      # Returns nil immediately.
      def submit(name, &block)
        task = Task.new(name: name.to_sym, block: block)
        thread = Thread.new(task) { |t| @queue << run(t) }
        @mutex.synchronize { @threads << thread }
        nil
      end

      # Waits up to *timeout* seconds for in-flight threads to finish, then kills any
      # remaining live threads. Used by Runtime during teardown.
      def shutdown(timeout: 0.0)
        threads = @mutex.synchronize { @threads.dup }
        threads.each { |thread| thread.join(timeout) }
        threads.each do |thread|
          next unless thread.alive?

          thread.kill
          thread.join(0)
        end
      end

      private

      # Invokes the task's block and wraps the result (or rescued exception) in a TaskEvent.
      def run(task)
        Events::TaskEvent.new(name: task.name, value: task.call)
      rescue StandardError, ScriptError => e
        Events::TaskEvent.new(name: task.name, error: e)
      end
    end
  end
end
