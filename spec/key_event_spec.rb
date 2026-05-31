# frozen_string_literal: true

RSpec.describe Charming::KeyEvent do
  it "normalizes key names to symbols" do
    event = described_class.new(key: "q", char: "q")

    expect(event.key).to eq(:q)
    expect(event.char).to eq("q")
  end
end
