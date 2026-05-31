# frozen_string_literal: true

RSpec.describe Charming::Screen do
  describe "#narrow?" do
    it "detects screens below a width threshold" do
      screen = described_class.new(width: 60, height: 24)

      expect(screen).to be_narrow(below: 72)
    end

    it "can require a minimum height" do
      screen = described_class.new(width: 60, height: 10)

      expect(screen).not_to be_narrow(below: 72, min_height: 20)
    end
  end
end
