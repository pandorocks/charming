# frozen_string_literal: true

RSpec.describe Charming::Screen do
  it "stores terminal dimensions" do
    screen = described_class.new(width: 80, height: 24)

    expect(screen.width).to eq(80)
    expect(screen.height).to eq(24)
  end
end
