# frozen_string_literal: true

module Journal
  class StatsState < ApplicationState
    attribute :exporting, :boolean, default: false
    attribute :export_current, :integer, default: 0
    attribute :export_total, :integer, default: 0
    attribute :activity_index, :integer, default: 0
  end
end
