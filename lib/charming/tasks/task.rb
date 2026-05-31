# frozen_string_literal: true

module Charming
  module Tasks
    Task = Data.define(:name, :block) do
      def call = block.call
    end
  end
end
