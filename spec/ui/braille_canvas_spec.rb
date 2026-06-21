# frozen_string_literal: true

RSpec.describe Charming::UI::BrailleCanvas do
  it "reports cell dimensions derived from the pixel size" do
    canvas = described_class.new(5, 9)

    expect([canvas.cols, canvas.rows]).to eq([3, 3]) # ceil(5/2), ceil(9/4)
  end

  it "sets a single top-left dot to the first braille glyph" do
    canvas = described_class.new(2, 4)
    canvas.set(0, 0)

    expect(canvas.to_s).to eq("⠁")
  end

  it "sets all eight dots in a cell to the full braille glyph" do
    canvas = described_class.new(2, 4)
    (0..1).each { |x| (0..3).each { |y| canvas.set(x, y) } }

    expect(canvas.to_s).to eq("⣿")
  end

  it "ignores out-of-range points" do
    canvas = described_class.new(2, 4)
    canvas.set(9, 9).set(-1, 0)

    expect(canvas.to_s).to eq("⠀")
  end

  it "unsets a dot" do
    canvas = described_class.new(2, 4)
    canvas.set(0, 0).unset(0, 0)

    expect(canvas.to_s).to eq("⠀")
  end

  it "draws a horizontal line across two cells" do
    canvas = described_class.new(4, 4)
    canvas.line(0, 0, 3, 0)

    # Each cell's top-left+top-right dots (0x01 | 0x08 = 0x09) → U+2809.
    expect(canvas.to_s).to eq("⠉⠉")
  end

  it "renders one line per cell row" do
    canvas = described_class.new(2, 8)
    canvas.set(0, 0).set(0, 7)

    expect(canvas.to_s.lines.length).to eq(2)
  end
end
