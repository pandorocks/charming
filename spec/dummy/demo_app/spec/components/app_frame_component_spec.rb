# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DemoApp::AppFrameComponent do
  describe "#render" do
    it "returns a string" do
      component = described_class.new(
        title: "DemoApp",
        status: "Idle",
        progress: 0,
        message: "Ready"
      )

      expect(component.render).to be_a(String)
    end

    it "renders visible progress while loading" do
      component = described_class.new(
        title: "DemoApp",
        status: "Loading",
        progress: 3,
        message: "Working"
      )

      expect(component.render).to include("[===       ] Working")
    end
  end
end
