# frozen_string_literal: true

RSpec.describe Charming::Presentation::Components::Spinner do
  it "renders the current frame" do
    spinner = described_class.new(frames: %w[a b], index: 1)

    expect(spinner.render).to eq("b")
  end

  it "renders an optional label" do
    spinner = described_class.new(frames: ["-"], label: "Loading")

    expect(spinner.render).to eq("- Loading")
  end

  it "advances through frames cyclically" do
    spinner = described_class.new(frames: %w[a b])

    expect(spinner.tick).to eq(spinner)
    expect(spinner.render).to eq("b")

    spinner.tick
    expect(spinner.render).to eq("a")
  end

  it "requires at least one frame" do
    expect { described_class.new(frames: []) }.to raise_error(ArgumentError, "frames cannot be empty")
  end
end
