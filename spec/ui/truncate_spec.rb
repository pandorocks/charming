# frozen_string_literal: true

RSpec.describe Charming::UI::Truncate do
  it "returns text unchanged when it fits" do
    expect(described_class.tail("Hello", 10)).to eq("Hello")
  end

  it "truncates overflowing text with a trailing ellipsis" do
    expect(described_class.tail("Hello world", 8)).to eq("Hello w…")
  end

  it "supports a custom ellipsis" do
    expect(described_class.tail("Hello world", 8, ellipsis: "...")).to eq("Hello...")
  end

  it "preserves ANSI styling active at the cut" do
    expect(described_class.tail("\e[31mHello world\e[0m", 8)).to eq("\e[31mHello w\e[0m…")
  end

  it "never splits a double-width glyph at the cut" do
    # "界界界" is 6 columns; cutting at 4 leaves 3 columns for glyphs (ellipsis
    # takes 1), so the third glyph is dropped and its half-column padded.
    expect(described_class.tail("界界界", 4)).to eq("界 …")
  end

  it "truncates each line of a multi-line block independently" do
    expect(described_class.tail("Hello world\nHi", 8)).to eq("Hello w…\nHi")
  end

  it "degrades to a bare slice when the ellipsis cannot fit" do
    expect(described_class.tail("Hello", 1, ellipsis: "...")).to eq("H")
  end
end
