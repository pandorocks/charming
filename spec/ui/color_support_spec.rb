# frozen_string_literal: true

RSpec.describe Charming::UI::ColorSupport do
  after { described_class.level = :truecolor } # restore the spec_helper pin

  describe ".detect" do
    it "honors NO_COLOR above everything" do
      expect(described_class.detect({"NO_COLOR" => "1", "COLORTERM" => "truecolor"})).to eq(:none)
    end

    it "detects truecolor from COLORTERM" do
      expect(described_class.detect({"COLORTERM" => "truecolor", "TERM" => "xterm"})).to eq(:truecolor)
      expect(described_class.detect({"COLORTERM" => "24bit", "TERM" => "xterm"})).to eq(:truecolor)
    end

    it "detects 256 colors from TERM" do
      expect(described_class.detect({"TERM" => "xterm-256color"})).to eq(:color256)
    end

    it "treats dumb terminals as no color" do
      expect(described_class.detect({"TERM" => "dumb"})).to eq(:none)
    end

    it "falls back to 16 colors" do
      expect(described_class.detect({"TERM" => "xterm"})).to eq(:color16)
    end
  end

  describe ".at_least?" do
    it "compares levels" do
      described_class.level = :color256
      expect(described_class.at_least?(:color16)).to be true
      expect(described_class.at_least?(:truecolor)).to be false
    end
  end

  describe ".hex_to_256" do
    it "maps pure red to the cube" do
      expect(described_class.hex_to_256("#ff0000")).to eq(196)
    end

    it "maps grays to the grayscale ramp" do
      index = described_class.hex_to_256("#808080")
      expect(index).to be_between(232, 255)
    end

    it "maps white and black to extremes" do
      expect(described_class.hex_to_256("#000000")).to eq(16)
      expect(described_class.hex_to_256("#ffffff")).to eq(231)
    end
  end

  describe ".hex_to_16" do
    it "maps red-ish colors to red" do
      expect([31, 91]).to include(described_class.hex_to_16("#cc3333"))
    end

    it "maps white to bright white" do
      expect(described_class.hex_to_16("#ffffff")).to eq(97)
    end
  end

  describe "ANSICodes degradation" do
    def codes_for(color, level)
      described_class.level = level
      Charming::UI::ANSICodes.new(attributes: [], foreground: color, background: nil).codes
    end

    it "emits truecolor sequences at :truecolor" do
      expect(codes_for("#ff0000", :truecolor)).to eq([38, 2, 255, 0, 0])
    end

    it "downconverts hex to a 256 index at :color256" do
      expect(codes_for("#ff0000", :color256)).to eq([38, 5, 196])
    end

    it "downconverts hex to a basic code at :color16" do
      expect(codes_for("#ff0000", :color16).length).to eq(1)
      expect(codes_for("#ff0000", :color16).first).to be_between(30, 97)
    end

    it "downconverts 256 indexes to basic codes at :color16" do
      expect(codes_for(196, :color16).first).to be_between(30, 97)
    end

    it "emits nothing at :none" do
      expect(codes_for("#ff0000", :none)).to eq([])
    end

    it "keeps named colors at every level except :none" do
      expect(codes_for(:red, :color16)).to eq([31])
      expect(codes_for(:red, :none)).to eq([])
    end
  end
end
