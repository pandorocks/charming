# frozen_string_literal: true

module DemoApp
  class TablesModel < ApplicationModel
    attribute :title, :string, default: "People"

    attr_reader :header, :rows
    attr_accessor :last_selected

    def initialize(**attributes)
      super
      @header = %w[Name Age City]
      @rows = [
        ["Alice",   30, "New York"],
        ["Bob",     25, "San Francisco"],
        ["Charlie", 35, "Seattle"],
        ["Diana",   28, "Portland"],
        ["Eve",     42, "Austin"]
      ]
      @last_selected = nil
    end
  end
end
