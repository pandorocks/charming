# frozen_string_literal: true

RSpec.describe Charming::Presentation::UI::BorderPainter do
  let(:normal_border) { Charming::Presentation::UI::Border.fetch(:normal) }
  let(:rounded_border) { Charming::Presentation::UI::Border.fetch(:rounded) }

  describe "#paint" do
    it "draws all four sides of a normal border" do
      painter = described_class.new(border: normal_border)

      result = painter.paint(["Hi"], 2)

      expect(result).to eq(["+--+", "|Hi|", "+--+"])
    end

    it "uses the supplied border's characters" do
      painter = described_class.new(border: rounded_border)

      result = painter.paint(["Hi"], 2)

      expect(result).to eq(["╭──╮", "│Hi│", "╰──╯"])
    end

    it "draws only the requested sides" do
      painter = described_class.new(border: normal_border, sides: %i[top bottom])

      result = painter.paint(["Hi"], 2)

      # Without :left/:right, the horizontal border has no corner characters.
      expect(result).to eq(["--", "Hi", "--"])
    end

    it "omits corners when only one horizontal side is requested" do
      painter = described_class.new(border: normal_border, sides: %i[top])

      result = painter.paint(["Hi"], 2)

      expect(result).to eq(["--", "Hi"])
    end

    it "draws corners when all four sides are present" do
      painter = described_class.new(border: normal_border, sides: %i[top right bottom left])

      result = painter.paint(["Hi"], 2)

      expect(result).to eq(["+--+", "|Hi|", "+--+"])
    end

    it "omits side edges when only horizontal sides are present" do
      painter = described_class.new(border: normal_border, sides: %i[top bottom])

      result = painter.paint(["Hi"], 2)

      expect(result[1]).to eq("Hi")
    end

    it "renders colored borders using the supplied foreground" do
      painter = described_class.new(border: normal_border, foreground: :red)

      result = painter.paint(["Hi"], 2)

      # BorderPainter only colors the border characters; the body content sits raw
      # between two colored edges. Outer-styling of the body happens in Style#render
      # via apply_ansi and is tested in style_spec.rb.
      expect(result).to eq([
        "\e[31m+--+\e[0m",
        "\e[31m|\e[0mHi\e[31m|\e[0m",
        "\e[31m+--+\e[0m"
      ])
    end

    it "applies a background color to the border characters" do
      painter = described_class.new(border: normal_border, foreground: :cyan, background: :black)

      result = painter.paint(["Hi"], 2)

      expect(result).to eq([
        "\e[36;40m+--+\e[0m",
        "\e[36;40m|\e[0mHi\e[36;40m|\e[0m",
        "\e[36;40m+--+\e[0m"
      ])
    end

    it "pads body lines to the inner width" do
      painter = described_class.new(border: normal_border)

      result = painter.paint(["a", "longer line"], 12)

      expect(result[1]).to eq("|a           |")
      expect(result[2]).to eq("|longer line |")
    end
  end
end
