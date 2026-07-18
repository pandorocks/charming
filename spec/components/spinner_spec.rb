# frozen_string_literal: true

RSpec.describe Charming::Components::Spinner do
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

  describe "named styles" do
    it "renders a preset style's frames" do
      spinner = described_class.new(style: :dots)

      expect(spinner.render).to eq("⠋")
      expect(spinner.tick.render).to eq("⠙")
    end

    it "ships the bubbles-inspired preset roster" do
      %i[line dots mini_dot jump pulse points globe moon meter hamburger ellipsis].each do |style|
        expect(described_class.new(style: style).render).not_to be_empty
      end
    end

    it "lets explicit frames override a style" do
      spinner = described_class.new(style: :dots, frames: %w[x])

      expect(spinner.render).to eq("x")
    end

    it "rejects unknown styles" do
      expect { described_class.new(style: :warp) }.to raise_error(ArgumentError, /unknown spinner style/)
    end
  end
end
