# frozen_string_literal: true

RSpec.describe Charming::Presentation::UI::ANSICodes do
  describe ".codes" do
    it "encodes attributes as ANSI numeric codes" do
      codes = described_class.new(attributes: [:bold, :italic], foreground: nil, background: nil).codes

      expect(codes).to eq([1, 3])
    end

    it "encodes a named foreground color" do
      codes = described_class.new(attributes: [], foreground: :cyan, background: nil).codes

      expect(codes).to eq([36])
    end

    it "encodes a named background color with +10 offset" do
      codes = described_class.new(attributes: [], foreground: nil, background: :red).codes

      expect(codes).to eq([41])
    end

    it "encodes a 256-color indexed foreground as 38;5;n" do
      codes = described_class.new(attributes: [], foreground: 45, background: nil).codes

      expect(codes).to eq([38, 5, 45])
    end

    it "encodes a 256-color indexed background as 48;5;n" do
      codes = described_class.new(attributes: [], foreground: nil, background: 200).codes

      expect(codes).to eq([48, 5, 200])
    end

    it "encodes a #rrggbb truecolor foreground as 38;2;r;g;b" do
      codes = described_class.new(attributes: [], foreground: "#112233", background: nil).codes

      expect(codes).to eq([38, 2, 17, 34, 51])
    end

    it "encodes a #rrggbb truecolor background as 48;2;r;g;b" do
      codes = described_class.new(attributes: [], foreground: nil, background: "#aabbcc").codes

      expect(codes).to eq([48, 2, 170, 187, 204])
    end

    it "raises on an unknown color" do
      ansi = described_class.new(attributes: [], foreground: :not_a_color, background: nil)

      expect { ansi.codes }.to raise_error(ArgumentError, /unknown color/)
    end

    it "raises on an out-of-range indexed color" do
      ansi = described_class.new(attributes: [], foreground: 999, background: nil)

      expect { ansi.codes }.to raise_error(ArgumentError, /between 0 and 255/)
    end

    it "raises on a malformed truecolor string" do
      ansi = described_class.new(attributes: [], foreground: "#zzz", background: nil)

      expect { ansi.codes }.to raise_error(ArgumentError, /#rrggbb/)
    end

    it "returns just attribute codes when no colors are set" do
      codes = described_class.new(attributes: [:underline], foreground: nil, background: nil).codes

      expect(codes).to eq([4])
    end
  end

  describe "#apply" do
    it "returns the value unchanged when no codes are present" do
      ansi = described_class.new(attributes: [], foreground: nil, background: nil)

      expect(ansi.apply("hello")).to eq("hello")
    end

    it "wraps the value with start codes and a trailing reset" do
      ansi = described_class.new(attributes: [:bold], foreground: nil, background: nil)

      expect(ansi.apply("Hi")).to eq("\e[1mHi\e[0m")
    end

    it "re-asserts codes on every newline so styling spans rows" do
      ansi = described_class.new(attributes: [:bold], foreground: :red, background: nil)

      expect(ansi.apply("a\nb")).to eq("\e[1;31ma\e[0m\n\e[1;31mb\e[0m")
    end

    it "does not double up when a reset already appears mid-line" do
      ansi = described_class.new(attributes: [:bold], foreground: :cyan, background: nil)
      inner_reset = "\e[1mBold\e[0m"

      # The original input has an inner reset; apply should re-emit the start after it
      # so the outer style persists past the inner reset.
      result = ansi.apply(inner_reset)
      expect(result).to start_with("\e[1;36m")
      expect(result).to include("\e[0m\e[1;36m")
      expect(result).to end_with("\e[0m")
    end
  end
end
