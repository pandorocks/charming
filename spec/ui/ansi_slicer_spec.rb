# frozen_string_literal: true

RSpec.describe Charming::UI::ANSISlicer do
  describe ".slice" do
    it "returns an empty string when width is non-positive" do
      expect(described_class.slice("hello", 0, 0)).to eq("")
      expect(described_class.slice("hello", 0, -1)).to eq("")
    end

    it "slices a plain ASCII string" do
      expect(described_class.slice("hello", 1, 3)).to eq("ell")
    end

    it "preserves an active ANSI attribute that spans the slice" do
      line = "\e[2mhello\e[0m"

      expect(described_class.slice(line, 1, 3)).to eq("\e[2mell\e[0m")
    end

    it "returns an empty string when the visible range falls between visible characters" do
      line = "\e[2mhello\e[0m"

      expect(described_class.slice(line, 5, 1)).to eq("")
    end

    it "advances the cursor by visual width for full-width characters" do
      expect(described_class.slice("ＡＢＣ", 0, 2)).to eq("Ａ")
      expect(described_class.slice("ＡＢＣ", 2, 2)).to eq("Ｂ")
    end

    it "renders the in-range columns of a boundary-straddling wide glyph as spaces" do
      # Columns 1 and 2 are the right half of Ａ and the left half of Ｂ, so a
      # width-2 slice over them must be two spaces, not the over-included "ＡＢ".
      result = described_class.slice("ＡＢＣ", 1, 2)

      expect(result).to eq("  ")
      expect(Charming::UI::Width.measure(result)).to eq(2)
    end

    it "blanks only the cut half of a wide glyph and keeps in-range neighbours" do
      result = described_class.slice("Ａbc", 1, 3)

      expect(result).to eq(" bc")
      expect(Charming::UI::Width.measure(result)).to eq(3)
    end

    it "keeps a multi-codepoint emoji grapheme together as one unit" do
      # "🧙‍♂️" is a four-codepoint ZWJ sequence rendered as one double-width glyph.
      expect(described_class.slice("🧙‍♂️xy", 0, 2)).to eq("🧙‍♂️")
      expect(described_class.slice("🧙‍♂️xy", 2, 2)).to eq("xy")
    end

    it "blanks a multi-codepoint emoji grapheme that a boundary cuts through" do
      result = described_class.slice("🧙‍♂️x", 1, 2)

      expect(result).to eq(" x")
      expect(Charming::UI::Width.measure(result)).to eq(2)
    end

    it "returns just an empty string when the start column is past the end of the line" do
      expect(described_class.slice("hello", 10, 3)).to eq("")
    end

    it "clamps slices that go past the end of the line" do
      expect(described_class.slice("hello", 3, 100)).to eq("lo")
    end

    it "emits an ANSI token that starts inside the visible range, including post-reset characters" do
      line = "a\e[31mb\e[0mc"

      expect(described_class.slice(line, 1, 3)).to eq("\e[31mb\e[0mc")
    end

    it "emits a non-reset ANSI token that is active throughout the slice with a trailing reset" do
      line = "a\e[31m\e[4mbcde"

      expect(described_class.slice(line, 0, 3)).to eq("a\e[31m\e[4mbc\e[0m")
    end

    it "re-emits active styles at the start of the slice after off-screen ANSI" do
      line = "\e[2mxxx\e[0m\e[31myyy\e[0m"

      expect(described_class.slice(line, 3, 3)).to eq("\e[31myyy\e[0m")
    end
  end

  describe ".slice_range" do
    it "slices a plain string by start and end column" do
      expect(described_class.slice_range("hello", 1, 4)).to eq("ell")
    end

    it "preserves ANSI styling across an explicit end column" do
      line = "\e[2mhello\e[0m"

      expect(described_class.slice_range(line, 1, 4)).to eq("\e[2mell\e[0m")
    end
  end
end
