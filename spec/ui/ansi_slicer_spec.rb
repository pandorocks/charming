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
