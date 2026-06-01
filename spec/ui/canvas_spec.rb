# frozen_string_literal: true

RSpec.describe Charming::Presentation::UI::Canvas do
  describe ".new" do
    it "builds a blank grid of the given dimensions" do
      canvas = described_class.new(3, 2)

      expect(canvas.to_s).to eq("   \n   ")
    end
  end

  describe "#place" do
    it "places content at the top-left by default" do
      canvas = described_class.new(5, 2)

      result = canvas.place("AB", top: 0, left: 0)

      expect(result).to eq("AB   \n     ")
    end

    it "centers content when given :center coordinates" do
      canvas = described_class.new(5, 3)

      result = canvas.place("X", top: :center, left: :center)

      expect(result).to eq("     \n  X  \n     ")
    end

    it "wraps the canvas with a background style when given a color" do
      canvas = described_class.new(3, 1)
      bg = "\e[48;2;255;0;0m"

      result = canvas.place("X", background: "#ff0000")

      expect(result).to eq("#{bg}X  \e[0m")
    end
  end

  describe "#overlay" do
    it "overlays content onto a non-blank base at the center" do
      canvas = described_class.parse(".....\n.....\n.....")

      result = canvas.overlay("X").to_s

      expect(result).to eq(".....\n..X..\n.....")
    end

    it "preserves base content to the left and right of the overlay" do
      canvas = described_class.parse("|.....|\n|.....|\n|.....|")

      result = canvas.overlay("XXX", top: 1, left: 2).to_s

      expect(result).to eq("|.....|\n|.XXX.|\n|.....|")
    end

    it "preserves ANSI styling on the base around the overlay" do
      styled = Charming::Presentation::UI.style.faint.render(".....")
      canvas = described_class.parse(styled)

      result = canvas.overlay("X", left: 2).to_s

      expect(result).to eq("\e[2m..\e[0mX\e[2m..\e[0m")
    end

    it "clips overlay lines that extend past the canvas height" do
      canvas = described_class.parse("...\n...")

      result = canvas.overlay("ABCDE\nFGHIJ", top: 1, left: 1).to_s

      expect(result).to eq("...\n.AB")
    end
  end

  describe ".parse" do
    it "reconstructs a canvas from a multi-line string" do
      canvas = described_class.parse("AB\nCD")

      expect(canvas.to_s).to eq("AB\nCD")
    end
  end

  describe ".offset" do
    it "returns the value verbatim for non-:center" do
      expect(described_class.offset(2, 10, 3)).to eq(2)
    end

    it "centers the size within the available space for :center" do
      expect(described_class.offset(:center, 10, 3)).to eq(3)
    end

    it "clamps the centered offset to non-negative" do
      expect(described_class.offset(:center, 1, 5)).to eq(0)
    end
  end
end
