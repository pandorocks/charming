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

    it "decodes shift, alt, and ctrl from the SGR button-code bits" do
      shift_click = described_class.parse("\e[<4;10;5M")
      alt_click = described_class.parse("\e[<8;10;5M")
      ctrl_click = described_class.parse("\e[<16;10;5M")
      all_click = described_class.parse("\e[<28;10;5M")

      expect(shift_click).to have_attributes(button_name: :left, shift: true, alt: false, ctrl: false)
      expect(alt_click).to have_attributes(button_name: :left, shift: false, alt: true, ctrl: false)
      expect(ctrl_click).to have_attributes(button_name: :left, shift: false, alt: false, ctrl: true)
      expect(all_click).to have_attributes(button_name: :left, shift: true, alt: true, ctrl: true)
    end

    it "decodes modified scroll events to their base wheel direction" do
      event = described_class.parse("\e[<68;10;5M")

      expect(event.button_name).to eq(:scroll_up)
      expect(event.shift).to be(true)
      expect(event.scroll?).to be(true)
    end

    it "marks SGR release sequences (final m) as releases, not clicks" do
      event = described_class.parse("\e[<0;10;5m")

      expect(event.release?).to be(true)
      expect(event.click?).to be(false)
      expect(event.button_name).to eq(:left)
    end

    it "decodes drag motion from the SGR motion bit" do
      event = described_class.parse("\e[<32;10;5M")

      expect(event.motion?).to be(true)
      expect(event.drag?).to be(true)
      expect(event.button_name).to eq(:left)
      expect(event.click?).to be(false)
    end

    it "decodes buttonless hover motion" do
      event = described_class.parse("\e[<35;10;5M")

      expect(event.motion?).to be(true)
      expect(event.drag?).to be(false)
      expect(event.click?).to be(false)
    end

    it "decodes modifiers on legacy sequences" do
      # Legacy byte: 32 + button 0 + shift bit 4 = 36 → "$"
      event = described_class.parse("\e[M\x24\x29\x25")

      expect(event.button_name).to eq(:left)
      expect(event.shift).to be(true)
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
