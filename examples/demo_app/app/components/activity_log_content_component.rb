# frozen_string_literal: true

module DemoApp
  class ActivityLogContentComponent < Charming::Component
    def render
      home.entries.join("\n")
    end
  end
end
