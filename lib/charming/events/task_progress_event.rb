# frozen_string_literal: true

module Charming
  module Events
    # TaskProgressEvent reports incremental progress from a running background task.
    # *name* matches the task name, *current*/*total* describe completion (total may be
    # nil for indeterminate work), and *message* is an optional human-readable status.
    TaskProgressEvent = Data.define(:name, :current, :total, :message) do
      def initialize(name:, current:, total: nil, message: nil)
        super
      end

      # Completion as a 0.0..1.0 fraction, or nil when the total is unknown.
      def fraction
        return nil unless total&.positive?

        (current.to_f / total).clamp(0.0, 1.0)
      end
    end
  end
end
