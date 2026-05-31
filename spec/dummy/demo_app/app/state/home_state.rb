# frozen_string_literal: true

module DemoApp
  class HomeState < ApplicationState
    attribute :title, :string, default: "DemoApp"
    attribute :status, :string, default: "Idle"
    attribute :message, :string, default: "Tab content, then press r for async task."
    attribute :progress, :integer, default: 0
    attribute :activity_index, :integer, default: 0
  end
end
