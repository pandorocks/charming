# frozen_string_literal: true

require "charming_test_app"

RSpec.describe CharmingTestApp::AppFrameComponent do
  describe "#render" do
    it "returns a string" do
      component = described_class.new(title: "CharmingTestApp")
      expect(component.render).to be_a(String)
    end
  end
end
