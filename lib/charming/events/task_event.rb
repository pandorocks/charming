# frozen_string_literal: true

module Charming
  module Events
    # TaskEvent represents background task completion. *name* is the declared task identifier, *value* carries
    # the return result and *error* captures any exception raised during execution. The `error?` predicate
    # simplifies error handling in controller handlers.
    TaskEvent = Data.define(:name, :value, :error) do
      def initialize(name:, value: nil, error: nil)
        super
      end

      # Returns `true` when the task finished with a non-nil exception.
      def error?
        !error.nil?
      end
    end
  end
end
