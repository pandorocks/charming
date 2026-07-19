# frozen_string_literal: true

RSpec.describe Charming::Spring do
  let(:delta_time) { Charming.fps(60) }

  def simulate(spring, ticks, target: 100.0)
    positions = []
    pos = 0.0
    vel = 0.0
    ticks.times do
      pos, vel = spring.update(pos, vel, target)
      positions << pos
    end
    positions
  end

  describe "Charming.fps" do
    it "returns the seconds-per-frame delta for a frame rate" do
      expect(Charming.fps(60)).to eq(1.0 / 60)
    end
  end

  it "does not move when angular frequency is zero" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 0.0)

    expect(spring.update(3.0, 4.0, 100.0)).to eq([3.0, 4.0])
  end

  it "clamps negative parameters to zero instead of raising" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: -6.0, damping_ratio: -1.0)

    expect(spring.update(3.0, 4.0, 100.0)).to eq([3.0, 4.0])
  end

  it "matches harmonica for a critically damped spring" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 1.0)

    pos, vel = spring.update(0.0, 0.0, 100.0)
    expect(pos).to be_within(1e-9).of(0.467884016044451)
    expect(vel).to be_within(1e-9).of(54.290245082157561)

    pos, vel = spring.update(pos, vel, 100.0)
    expect(pos).to be_within(1e-9).of(1.752309630642188)
    expect(vel).to be_within(1e-9).of(98.247690369357798)
  end

  it "matches harmonica for an under-damped spring" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 0.5)

    pos, vel = spring.update(0.0, 0.0, 100.0)
    expect(pos).to be_within(1e-9).of(0.483341527802295)
    expect(vel).to be_within(1e-9).of(57.002450011755968)

    pos, vel = spring.update(pos, vel, 100.0)
    expect(pos).to be_within(1e-9).of(1.866924450652590)
    expect(vel).to be_within(1e-9).of(108.038401485730915)
  end

  it "matches harmonica for an over-damped spring" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 2.0)

    pos, vel = spring.update(0.0, 0.0, 100.0)
    expect(pos).to be_within(1e-9).of(0.439144216137038)
    expect(vel).to be_within(1e-9).of(49.369833102714331)

    pos, vel = spring.update(pos, vel, 100.0)
    expect(pos).to be_within(1e-9).of(1.553410072678929)
    expect(vel).to be_within(1e-9).of(82.056853868322051)
  end

  it "converges to the target without overshooting when critically damped" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 1.0)

    positions = simulate(spring, 300)

    expect(positions.max).to be <= 100.0 + 1e-9
    expect(positions.last).to be_within(0.01).of(100.0)
  end

  it "overshoots the target and then converges when under-damped" do
    spring = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 0.5)

    positions = simulate(spring, 300)

    expect(positions.max).to be > 100.0
    expect(positions.last).to be_within(0.01).of(100.0)
  end

  it "converges more slowly than critical damping when over-damped, without overshooting" do
    critical = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 1.0)
    over = described_class.new(delta_time: delta_time, angular_frequency: 6.0, damping_ratio: 2.0)

    critical_positions = simulate(critical, 60)
    over_positions = simulate(over, 60)

    expect(over_positions.max).to be <= 100.0 + 1e-9
    expect(over_positions.last).to be < critical_positions.last
  end

  describe "#settled?" do
    let(:spring) { described_class.new(delta_time: delta_time) }

    it "is true when position and velocity are within epsilon of rest" do
      expect(spring.settled?(99.995, 0.005, 100.0)).to be(true)
    end

    it "is false while the position is away from the target" do
      expect(spring.settled?(90.0, 0.0, 100.0)).to be(false)
    end

    it "is false while velocity remains" do
      expect(spring.settled?(100.0, 5.0, 100.0)).to be(false)
    end

    it "honors a custom epsilon" do
      expect(spring.settled?(99.5, 0.0, 100.0, epsilon: 1.0)).to be(true)
    end
  end

  it "is frozen" do
    expect(described_class.new(delta_time: delta_time)).to be_frozen
  end
end
