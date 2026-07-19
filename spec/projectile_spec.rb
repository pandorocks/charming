# frozen_string_literal: true

RSpec.describe Charming::Projectile do
  let(:delta_time) { Charming.fps(60) }

  it "advances position by the current velocity before accelerating" do
    projectile = described_class.new(
      delta_time: delta_time,
      position: described_class::Point.new(x: 10.0, y: 5.0),
      acceleration: described_class::TERMINAL_GRAVITY
    )

    first = projectile.update

    expect(first).to eq(described_class::Point.new(x: 10.0, y: 5.0, z: 0.0))
    expect(projectile.velocity.y).to be_within(1e-9).of(9.81 * delta_time)
  end

  it "moves under accumulated gravity on subsequent updates" do
    projectile = described_class.new(
      delta_time: delta_time,
      position: described_class::Point.new(x: 0.0, y: 0.0),
      acceleration: described_class::TERMINAL_GRAVITY
    )

    projectile.update
    second = projectile.update

    expect(second.y).to be_within(1e-9).of(9.81 * delta_time * delta_time)
    expect(projectile.velocity.y).to be_within(1e-9).of(2 * 9.81 * delta_time)
  end

  it "carries initial velocity through position updates" do
    projectile = described_class.new(
      delta_time: delta_time,
      position: described_class::Point.new(x: 0.0, y: 0.0),
      velocity: described_class::Vector.new(x: 60.0, y: 0.0)
    )

    position = projectile.update

    expect(position.x).to be_within(1e-9).of(1.0)
    expect(projectile.velocity).to eq(described_class::Vector.new(x: 60.0, y: 0.0, z: 0.0))
  end

  it "defines gravity constants for both coordinate origins" do
    expect(described_class::GRAVITY).to eq(described_class::Vector.new(x: 0.0, y: -9.81, z: 0.0))
    expect(described_class::TERMINAL_GRAVITY).to eq(described_class::Vector.new(x: 0.0, y: 9.81, z: 0.0))
  end

  it "defaults the z axis to zero for points and vectors" do
    expect(described_class::Point.new(x: 1.0, y: 2.0).z).to eq(0.0)
    expect(described_class::Vector.new(x: 1.0, y: 2.0).z).to eq(0.0)
  end

  it "exposes position, velocity, and acceleration readers" do
    projectile = described_class.new(
      delta_time: delta_time,
      position: described_class::Point.new(x: 1.0, y: 2.0),
      velocity: described_class::Vector.new(x: 3.0, y: 4.0),
      acceleration: described_class::GRAVITY
    )

    expect(projectile.position).to eq(described_class::Point.new(x: 1.0, y: 2.0, z: 0.0))
    expect(projectile.velocity).to eq(described_class::Vector.new(x: 3.0, y: 4.0, z: 0.0))
    expect(projectile.acceleration).to eq(described_class::GRAVITY)
  end
end
