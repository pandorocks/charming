# frozen_string_literal: true

module Charming
  module Tasks
    # Progress is the reporter handed to task blocks that accept an argument:
    #
    #   run_task(:import) do |progress|
    #     rows.each_with_index do |row, i|
    #       import(row)
    #       progress.report(i + 1, of: rows.length, message: row.name)
    #     end
    #   end
    #
    # Each `report` pushes a TaskProgressEvent onto the runtime queue, which dispatches
    # it to the controller's matching `on_task_progress` handler.
    class Progress
      def initialize(queue, name)
        @queue = queue
        @name = name
      end

      # Reports progress: *current* units done, optionally *of:* a total and with a
      # human-readable *message:*.
      def report(current, of: nil, message: nil)
        @queue << Events::TaskProgressEvent.new(name: @name, current: current, total: of, message: message)
        nil
      end
    end
  end
end
