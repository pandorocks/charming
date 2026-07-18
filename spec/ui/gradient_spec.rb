# frozen_string_literal: true

RSpec.describe Charming::UI::Gradient do
  it "blends two hex colors at a fractional position" do
    expect(described_class.blend("#000000", "#ffffff", 0.5)).to eq("#808080")
    expect(described_class.blend("#ff0000", "#0000ff", 0.0)).to eq("#ff0000")
    expect(described_class.blend("#ff0000", "#0000ff", 1.0)).to eq("#0000ff")
  end

  it "rejects colors that are not #rrggbb" do
    expect { described_class.blend("red", "#0000ff", 0.5) }.to raise_error(ArgumentError)
  end

  it "produces an evenly spaced ramp including both endpoints" do
    ramp = described_class.steps("#000000", "#ffffff", 3)

    expect(ramp).to eq(["#000000", "#808080", "#ffffff"])
  end

  it "produces a single-color ramp for a count of one" do
    expect(described_class.steps("#123456", "#ffffff", 1)).to eq(["#123456"])
  end

  it "colorizes text with a per-character gradient" do
    output = described_class.colorize("AB", from: "#000000", to: "#ffffff")

    expect(output).to eq("\e[38;2;0;0;0mA\e[0m\e[38;2;255;255;255mB\e[0m")
  end

  it "keeps multi-codepoint emoji intact while colorizing" do
    output = described_class.colorize("🧙‍♂️!", from: "#000000", to: "#ffffff")

    expect(output).to eq("\e[38;2;0;0;0m🧙‍♂️\e[0m\e[38;2;255;255;255m!\e[0m")
  end

  it "returns single-cluster text styled with the start color" do
    expect(described_class.colorize("A", from: "#ff0000", to: "#0000ff")).to eq("\e[38;2;255;0;0mA\e[0m")
  end
end
