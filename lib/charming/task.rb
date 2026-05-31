# frozen_string_literal: true

module Charming
  Task = Data.define(:name, :block) do
    def call = block.call
  end
end
