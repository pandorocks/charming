# frozen_string_literal: true

RSpec.describe Charming::Components::Stopwatch do
  it "starts at zero" do
    expect(described_class.new.render).to eq("00:00")
  end

  it "accumulates elapsed time only while running" do
    stopwatch = described_class.new

    stopwatch.tick
    expect(stopwatch.render).to eq("00:00")

    stopwatch.start
    stopwatch.tick(65)
    expect(stopwatch.render).to eq("01:05")

    stopwatch.stop
    stopwatch.tick(10)
    expect(stopwatch.render).to eq("01:05")
  end

  it "reports whether it is running" do
    stopwatch = described_class.new

    expect(stopwatch.running?).to be(false)
    stopwatch.start
    expect(stopwatch.running?).to be(true)
  end

  it "resets to zero and stops" do
    stopwatch = described_class.new
    stopwatch.start
    stopwatch.tick(30)

    stopwatch.reset

    expect(stopwatch.render).to eq("00:00")
    expect(stopwatch.running?).to be(false)
  end

  it "appends an optional label" do
    stopwatch = described_class.new(label: "elapsed")

    expect(stopwatch.render).to eq("00:00 elapsed")
  end

  it "accumulates fractional ticks while running" do
    stopwatch = described_class.new
    stopwatch.start

    6.times { stopwatch.tick(0.5) }

    expect(stopwatch.elapsed).to eq(3.0)
    expect(stopwatch.render).to eq("00:03")
  end
end
