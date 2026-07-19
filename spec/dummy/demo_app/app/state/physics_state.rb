# frozen_string_literal: true

module DemoApp
  class PhysicsState < ApplicationState
    attribute :x, :float, default: 2.0
    attribute :velocity, :float, default: 0.0
    attribute :target_x, :float, default: 2.0
  end
end
