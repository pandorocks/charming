# frozen_string_literal: true

RSpec.describe Charming::MouseEvent do
  it "creates a left click event" do
    event = described_class.new(button: 0, x: 10, y: 5)

    expect(event.button).to eq(0)
    expect(event.x).to eq(10)
    expect(event.y).to eq(5)
    expect(event.button_name).to eq(:left)
    expect(event.click?).to be true
    expect(event.scroll?).to be false
    expect(event.release?).to be false
  end

  it "creates a scroll up event" do
    event = described_class.new(button: 64, x: 5, y: 3)

    expect(event.button).to eq(64)
    expect(event.button_name).to eq(:scroll_up)
    expect(event.scroll?).to be true
  end

  it "creates a scroll down event" do
    event = described_class.new(button: 65, x: 5, y: 3)

    expect(event.button_name).to eq(:scroll_down)
    expect(event.scroll?).to be true
  end

  it "creates a release event" do
    event = described_class.new(button: 3, x: 1, y: 1)

    expect(event.button_name).to eq(:release)
    expect(event.release?).to be true
  end

  it "creates a middle click event" do
    event = described_class.new(button: 1, x: 0, y: 0)

    expect(event.button_name).to eq(:middle)
    expect(event.click?).to be true
  end

  it "creates a right click event" do
    event = described_class.new(button: 2, x: 0, y: 0)

    expect(event.button_name).to eq(:right)
    expect(event.click?).to be true
  end

  it "defaults modifier flags to false" do
    event = described_class.new(button: 0, x: 0, y: 0)

    expect(event.ctrl).to be false
    expect(event.alt).to be false
    expect(event.shift).to be false
  end

  it "tracks modifier flags" do
    event = described_class.new(button: 0, x: 0, y: 0, ctrl: true, alt: true, shift: true)

    expect(event.ctrl).to be true
    expect(event.alt).to be true
    expect(event.shift).to be true
  end

  it "handles unknown button codes" do
    event = described_class.new(button: 99, x: 0, y: 0)

    expect(event.button_name).to eq(:unknown)
    expect(event.click?).to be false
    expect(event.scroll?).to be false
    expect(event.release?).to be false
  end
end
