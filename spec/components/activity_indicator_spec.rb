# frozen_string_literal: true

RSpec.describe Charming::Presentation::Components::ActivityIndicator do
  def plain(value)
    Charming::Presentation::UI::Width.strip_ansi(value)
  end

  it "renders the requested indicator width" do
    indicator = described_class.new(width: 6, seed: 1)

    expect(plain(indicator.render).length).to eq(6)
  end

  it "renders an optional label with animated ellipsis" do
    indicator = described_class.new(width: 4, label: "Working", seed: 1)

    expect(plain(indicator.render)).to end_with(" Working.")
  end

  it "advances through frames cyclically" do
    indicator = described_class.new(width: 8, seed: 1)
    first = indicator.render

    expect(indicator.tick).to eq(indicator)
    expect(indicator.render).not_to eq(first)
  end

  it "renders deterministically for the same seed and index" do
    first = described_class.new(width: 8, index: 3, seed: "demo")
    second = described_class.new(width: 8, index: 3, seed: "demo")

    expect(first.render).to eq(second.render)
  end

  it "changes output for different indexes" do
    first = described_class.new(width: 8, index: 1, seed: "demo")
    second = described_class.new(width: 8, index: 2, seed: "demo")

    expect(first.render).not_to eq(second.render)
  end

  it "loops glyph frames every ten ticks" do
    first = described_class.new(width: 8, index: 0, seed: "demo")
    looped = described_class.new(width: 8, index: 10, seed: "demo")

    expect(first.render).to eq(looped.render)
  end

  it "uses deterministic per-cell random glyphs instead of ordered character movement" do
    indicator = described_class.new(width: 6, seed: "random", chars: %w[a b c d e f])

    expect(plain(indicator.render)).to eq("afcbcd")
  end

  it "clamps non-positive widths to one cell" do
    indicator = described_class.new(width: 0, seed: 1)

    expect(plain(indicator.render).length).to eq(1)
  end

  it "requires at least one character" do
    expect { described_class.new(chars: []) }.to raise_error(ArgumentError, "chars cannot be empty")
  end

  it "cycles the label ellipsis" do
    indicator = described_class.new(width: 4, label: "Working", index: 8, seed: 1)

    expect(plain(indicator.render)).to end_with(" Working...")
  end
end
