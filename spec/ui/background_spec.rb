# frozen_string_literal: true

RSpec.describe Charming::UI::Background do
  after { described_class.assume = nil }

  describe ".detect" do
    it "reads a light background from COLORFGBG" do
      expect(described_class.detect({"COLORFGBG" => "0;15"})).to eq(:light)
    end

    it "reads a dark background from COLORFGBG" do
      expect(described_class.detect({"COLORFGBG" => "15;0"})).to eq(:dark)
    end

    it "defaults to dark when the environment says nothing" do
      expect(described_class.detect({})).to eq(:dark)
    end
  end

  describe ".assume=" do
    it "overrides detection" do
      described_class.assume = :light

      expect(described_class.dark?).to be(false)
    end

    it "rejects unknown values" do
      expect { described_class.assume = :sepia }.to raise_error(ArgumentError)
    end
  end

  describe ".classify" do
    it "classifies dark colors by luminance" do
      expect(described_class.classify(30, 30, 46)).to eq(:dark)
    end

    it "classifies light colors by luminance" do
      expect(described_class.classify(250, 250, 240)).to eq(:light)
    end
  end

  describe ".parse_osc11" do
    it "classifies a 16-bit-per-channel OSC 11 reply" do
      expect(described_class.parse_osc11("\e]11;rgb:1e1e/1e1e/2e2e\e\\")).to eq(:dark)
      expect(described_class.parse_osc11("\e]11;rgb:fafa/fafa/f0f0\a")).to eq(:light)
    end

    it "returns nil for garbage or empty replies" do
      expect(described_class.parse_osc11("")).to be_nil
      expect(described_class.parse_osc11("\e[0m")).to be_nil
    end
  end
end
