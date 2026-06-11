# frozen_string_literal: true

module Charming
  module Tasks
    # ThreadedExecutor runs submitted tasks on background Ruby threads. Each submission
    # creates a new thread that invokes the block and pushes the resulting TaskEvent
    # onto the shared *queue*. Threads are tracked so `shutdown` can wait (or kill)
    # in-flight work, and tracked by name so `cancel` can interrupt a specific task.
    class ThreadedExecutor
      # *queue* is the thread-safe Queue (typically `runtime.@task_queue`) into which
      # completed TaskEvents are pushed.
      def initialize(queue)
        @queue = queue
        @threads = []
        @threads_by_name = {}
        @mutex = Mutex.new
        @shutting_down = false
      end

      # Wraps *block* in a Task and spawns a new thread to invoke it. The thread's
      # return value (or rescued exception) is pushed onto the queue as a TaskEvent.
      # Blocks that accept an argument receive a Progress reporter. *timeout* (seconds)
      # cancels the task when exceeded. Returns nil immediately. Raises if called after
      # shutdown has begun.
      def submit(name, timeout: nil, &block)
        task = Task.new(name: name.to_sym, block: block, timeout: timeout)
        @mutex.synchronize do
          raise "cannot submit task after shutdown" if @shutting_down

          thread = Thread.new(task) { |t| @queue << run(t) }
          @threads << thread
          @threads_by_name[task.name] = thread
        end
        nil
      end

      # Cancels the named in-flight task by raising Tasks::Cancelled in its thread.
      # The task completes with a TaskEvent whose error is the Cancelled exception.
      # No-op when the task isn't running.
      def cancel(name)
        thread = @mutex.synchronize { @threads_by_name[name.to_sym] }
        return unless thread&.alive?

        thread.raise(Cancelled, "task #{name} cancelled")
        nil
      end

      # Waits up to *timeout* seconds for in-flight threads to finish, then kills any
      # remaining live threads. Refuses new submissions once called.
      def shutdown(timeout: 2.0)
        threads = @mutex.synchronize do
          @shutting_down = true
          @threads.dup
        end
        threads.each { |thread| thread.join(timeout) }
        threads.each do |thread|
          next unless thread.alive?

          thread.kill
          thread.join(0)
        end
      end

      private

      # Invokes the task's block (passing a Progress reporter) and wraps the result
      # (or rescued exception) in a TaskEvent.
      def run(task)
        Events::TaskEvent.new(name: task.name, value: task.call(Progress.new(@queue, task.name)))
      rescue StandardError, ScriptError => e
        Events::TaskEvent.new(name: task.name, error: e)
      end
    end
  end
end
