# frozen_string_literal: true

RSpec.describe Charming::Components::Timer do
  it "renders the remaining time as mm:ss" do
    timer = described_class.new(duration: 90)

    expect(timer.render).to eq("01:30")
  end

  it "renders hours when the duration calls for them" do
    timer = described_class.new(duration: 3675)

    expect(timer.render).to eq("1:01:15")
  end

  it "counts down on tick and clamps at zero" do
    timer = described_class.new(duration: 2)

    timer.tick
    expect(timer.render).to eq("00:01")

    timer.tick
    timer.tick
    expect(timer.render).to eq("00:00")
  end

  it "reports expiry" do
    timer = described_class.new(duration: 1)

    expect(timer.expired?).to be(false)
    timer.tick
    expect(timer.expired?).to be(true)
  end

  it "resets to the original duration" do
    timer = described_class.new(duration: 5)

    timer.tick(3)
    timer.reset

    expect(timer.render).to eq("00:05")
  end

  it "appends an optional label" do
    timer = described_class.new(duration: 60, label: "remaining")

    expect(timer.render).to eq("01:00 remaining")
  end
end
