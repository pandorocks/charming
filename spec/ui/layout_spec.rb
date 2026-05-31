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

    expect(described_class.overlay(base, "X")).to eq(".....\n..X..\n.....")
  end

  it "preserves content to the left and right of the overlay" do
    base = "|.....|\n|.....|\n|.....|"

    expect(described_class.overlay(base, "XXX", top: 1, left: 2)).to eq("|.....|\n|.XXX.|\n|.....|")
  end

  it "preserves ansi styling around the overlay" do
    base = described_class.style.faint.render(".....")

    expect(described_class.overlay(base, "X", left: 2)).to eq("\e[2m..\e[0mX\e[2m..\e[0m")
  end

  it "slices visible text while preserving active ansi styling" do
    line = described_class.style.faint.render("hello")

    expect(described_class.visible_slice(line, 1, 3)).to eq("\e[2mell\e[0m")
  end

  it "paints the place canvas with a background color when provided" do
    filled = described_class.place("X", width: 3, height: 2, background: "#ff0000")
    bg = "\e[48;2;255;0;0m"

    expect(filled).to eq("#{bg}X  \e[0m\n#{bg}   \e[0m")
  end

  it "wraps every overlay position consistently with the canvas background" do
    filled = described_class.place("X", width: 3, height: 1, top: 0, left: 1, background: "#ff0000")
    bg = "\e[48;2;255;0;0m"

    expect(filled).to eq("#{bg} X \e[0m")
  end

  it "lets styled overlay content keep its own colors while restoring the canvas background after each reset" do
    styled = described_class.style.foreground(:green).render("X")
    filled = described_class.place(styled, width: 3, height: 1, top: 0, left: 1, background: "#ff0000")
    bg = "\e[48;2;255;0;0m"

    expect(filled).to eq("#{bg} \e[32mX\e[0m#{bg} \e[0m")
  end

  it "leaves place output unchanged when no background is given" do
    expect(described_class.place("X", width: 3, height: 2)).to eq("X  \n   ")
  end
end
