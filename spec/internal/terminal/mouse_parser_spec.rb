# frozen_string_literal: true

RSpec.describe Charming::Internal::Terminal::MouseParser do
  describe ".sequence?" do
    it "returns false for nil" do
      expect(described_class.sequence?(nil)).to be(false)
    end

    it "returns false for non-mouse strings" do
      expect(described_class.sequence?("hello")).to be(false)
      expect(described_class.sequence?("\e[A")).to be(false)
    end

    it "returns true for SGR mouse sequences" do
      expect(described_class.sequence?("\e[<0;10;5M")).to be(true)
    end

    it "returns true for legacy mouse sequences" do
      expect(described_class.sequence?("\e[M\x20\x29\x25")).to be(true)
    end
  end

  describe ".parse" do
    it "parses an SGR left button click" do
      event = described_class.parse("\e[<0;10;5M")

      expect(event).to be_a(Charming::Events::MouseEvent)
      expect(event.button).to eq(0)
      expect(event.x).to eq(9)
      expect(event.y).to eq(4)
    end

    it "parses an SGR scroll up (button 64)" do
      event = described_class.parse("\e[<64;10;5M")

      expect(event.button).to eq(64)
      expect(event.x).to eq(9)
      expect(event.y).to eq(4)
    end

    it "parses an SGR release (button 3)" do
      event = described_class.parse("\e[<3;10;5M")

      expect(event.button).to eq(3)
    end

    it "parses a legacy mouse sequence \\e[M + 3 bytes" do
      # bytes: 32 + button, 32 + col, 32 + row
      # button 0, col 10, row 5
      event = described_class.parse("\e[M\x20\x2A\x25")

      expect(event).to be_a(Charming::Events::MouseEvent)
      expect(event.button).to eq(0)
      expect(event.x).to eq(10)
      expect(event.y).to eq(5)
    end

    it "returns nil for nil input" do
      expect(described_class.parse(nil)).to be_nil
    end

    it "returns nil for malformed legacy mouse (wrong byte count)" do
      expect(described_class.parse("\e[Mab")).to be_nil
    end

    it "returns nil for an unknown mouse format" do
      expect(described_class.parse("\e[?1000h")).to be_nil
    end
  end
end
