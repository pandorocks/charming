# frozen_string_literal: true

require "charming_test_app"

RSpec.describe CharmingTestApp::HomeModel do
  describe "#title" do
    it "has the correct default string value" do
      instance = described_class.new
      expect(instance.title).to eq("CharmingTestApp")
    end

    it "accepts overridden title values" do
      instance = described_class.new(title: "Alternative")
      expect(instance.title).to eq("Alternative")
    end
  end
end
