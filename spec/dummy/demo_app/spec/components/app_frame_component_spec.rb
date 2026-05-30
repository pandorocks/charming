# frozen_string_literal: true

require "demo_app"

RSpec.describe DemoApp::AppFrameComponent do
  describe "#render" do
    it "returns a string" do
      component = described_class.new(
        title: "DemoApp",
        status: "Idle",
        message: "Ready"
      )

      expect(component.render).to be_a(String)
    end
  end
end
