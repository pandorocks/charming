# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DemoApp::HomeState do
  describe "#title" do
    it "has the correct default string value" do
      instance = described_class.new
      expect(instance.title).to eq("DemoApp")
    end

    it "accepts overridden title values" do
      instance = described_class.new(title: "Alternative")
      expect(instance.title).to eq("Alternative")
    end
  end

  describe "#activity_index" do
    it "defaults to zero" do
      instance = described_class.new

      expect(instance.activity_index).to eq(0)
    end
  end
end
