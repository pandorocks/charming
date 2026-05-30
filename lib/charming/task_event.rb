# frozen_string_literal: true

module Charming
  TaskEvent = Data.define(:name, :value, :error) do
    def initialize(name:, value: nil, error: nil)
      super
    end

    def error?
      !error.nil?
    end
  end
end
