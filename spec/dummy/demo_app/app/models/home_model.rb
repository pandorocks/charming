# frozen_string_literal: true

module DemoApp
  class HomeModel < ApplicationModel
    attribute :title, :string, default: "DemoApp"
  end
end
