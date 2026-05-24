# frozen_string_literal: true

RSpec.describe Charming::UI do
  it "joins blocks horizontally and pads shorter blocks" do
    left = "A\nBB"
    right = "1"

    expect(described_class.join_horizontal(left, right, gap: 1)).to eq("A  1\nBB  ")
  end

  it "joins blocks vertically with a gap" do
    expect(described_class.join_vertical("A", "B", gap: 1)).to eq("A\n\nB")
  end

  it "builds styles from the module helper" do
    expect(described_class.style.underline.render("Hi")).to eq("\e[4mHi\e[0m")
  end

  it "centers a block inside a fixed area" do
    expect(described_class.center("A", width: 3, height: 3)).to eq("   \n A \n   ")
  end

  it "overlays a block onto the center of another block" do
    base = ".....\n.....\n....."

    expect(described_class.overlay(base, "X")).to eq(".....\n  X  \n.....")
  end
end
