# frozen_string_literal: true

RSpec.describe Charming::UI::Width do
  it "measures Unicode display width" do
    expect(described_class.measure("界")).to eq(2)
  end

  it "ignores ANSI escape sequences" do
    expect(described_class.measure("\e[31mHi\e[0m")).to eq(2)
  end

  it "measures single-codepoint emoji as a double-width cell" do
    expect(described_class.measure("🧱")).to eq(2)
  end

  it "measures variation-selector emoji as double-width despite the Unicode tables" do
    # The unicode-display_width data reports "⚔️" as 1 and "🛡️" as 1, but
    # terminals render the VS16 emoji presentation as a 2-column glyph.
    expect(described_class.measure("⚔️")).to eq(2)
    expect(described_class.measure("🛡️")).to eq(2)
  end

  it "measures a ZWJ emoji sequence as a single double-width cell" do
    # "🧙‍♂️" is four codepoints the tables sum to 3; it is one terminal glyph.
    expect(described_class.measure("🧙‍♂️")).to eq(2)
  end

  it "measures mixed emoji-and-text lines by grapheme" do
    expect(described_class.measure(" 🛡️ : armor")).to eq(11)
  end

  it "ignores OSC 8 hyperlink sequences (ST-terminated)" do
    linked = "\e]8;;https://example.com\e\\Docs\e]8;;\e\\"
    expect(described_class.measure(linked)).to eq(4)
    expect(described_class.strip_ansi(linked)).to eq("Docs")
  end

  it "ignores BEL-terminated OSC sequences" do
    expect(described_class.strip_ansi("a\e]0;window title\ab")).to eq("ab")
  end

  it "ignores non-SGR CSI sequences" do
    expect(described_class.strip_ansi("a\e[2Jb\e[1;1Hc")).to eq("abc")
  end

  describe ".pad_to" do
    it "pads a line with spaces to the target display width" do
      expect(described_class.pad_to("ab", 5)).to eq("ab   ")
    end

    it "measures ANSI-styled text by its visible width" do
      expect(described_class.pad_to("\e[31mab\e[0m", 4)).to eq("\e[31mab\e[0m  ")
    end

    it "accounts for double-width characters" do
      expect(described_class.pad_to("界", 4)).to eq("界  ")
    end

    it "returns the line unchanged when already at or beyond the target" do
      expect(described_class.pad_to("abcdef", 4)).to eq("abcdef")
    end
  end

  describe ".widest" do
    it "returns the maximum display width across lines" do
      expect(described_class.widest(["ab", "界界界", "a"])).to eq(6)
    end

    it "ignores ANSI escapes when comparing" do
      expect(described_class.widest(["\e[1mxy\e[0m", "abc"])).to eq(3)
    end

    it "returns 0 for no lines" do
      expect(described_class.widest([])).to eq(0)
    end
  end
end
