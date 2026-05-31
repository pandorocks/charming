# frozen_string_literal: true

module Charming
  module Tasks
    class InlineExecutor
      def initialize(queue)
        @queue = queue
      end

      def submit(name, &block)
        task = Task.new(name: name.to_sym, block: block)
        @queue << run(task)
        nil
      end

      def shutdown(timeout: 0.0)
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
