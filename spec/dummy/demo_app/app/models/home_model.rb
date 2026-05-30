# frozen_string_literal: true

module DemoApp
  class HomeModel < ApplicationModel
    attribute :title, :string, default: "DemoApp"
    attribute :status, :string, default: "Idle"
    attribute :message, :string, default: "Press r to run an async task."
    attribute :progress, :integer, default: 0
  end
end
