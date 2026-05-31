# frozen_string_literal: true

module Charming
  module Tasks
    class ThreadedExecutor
      def initialize(queue)
        @queue = queue
        @threads = []
        @mutex = Mutex.new
      end

      def submit(name, &block)
        task = Task.new(name: name.to_sym, block: block)
        thread = Thread.new(task) { |t| @queue << run(t) }
        @mutex.synchronize { @threads << thread }
        nil
      end

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

      def run(task)
        Events::TaskEvent.new(name: task.name, value: task.call)
      rescue StandardError, ScriptError => e
        Events::TaskEvent.new(name: task.name, error: e)
      end
    end
  end
end
