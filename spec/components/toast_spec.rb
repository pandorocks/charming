# frozen_string_literal: true

RSpec.describe Charming::Components::Toast do
  it "renders the message in a bordered box" do
    toast = described_class.new(message: "Saved!")
    plain = Charming::UI::Width.strip_ansi(toast.render)
    expect(plain).to include("Saved!")
    expect(plain).to include("╭")
  end

  it "accepts a kind" do
    toast = described_class.new(message: "Boom", kind: :error)
    expect(toast.kind).to eq(:error)
    expect(toast.render).to include("Boom")
  end

  it "falls back to :info for unknown kinds" do
    toast = described_class.new(message: "x", kind: :bogus)
    expect(toast.kind).to eq(:info)
  end

  it "respects a fixed width" do
    toast = described_class.new(message: "hi", width: 20)
    first_line = Charming::UI::Width.strip_ansi(toast.render).lines.first.chomp
    # content width 20 + horizontal padding 2 + border columns 2
    expect(Charming::UI::Width.measure(first_line)).to eq(24)
  end
end
