# frozen_string_literal: true

RSpec.describe Charming::Components::Sparkline do
  it "maps an ascending series across the full range of bar glyphs" do
    expect(described_class.new(values: (0..7).to_a).render).to eq("▁▂▃▄▅▆▇█")
  end

  it "renders a flat series as the lowest bar" do
    expect(described_class.new(values: [5, 5, 5]).render).to eq("▁▁▁")
  end

  it "renders an empty series as an empty string" do
    expect(described_class.new(values: []).render).to eq("")
  end

  it "is one cell wide per value" do
    rendered = described_class.new(values: [3, 1, 4, 1, 5, 9, 2]).render

    expect(Charming::UI::Width.measure(rendered)).to eq(7)
  end

  it "applies an optional style" do
    rendered = described_class.new(values: [1, 2], style: Charming::UI.style.foreground(:cyan)).render

    expect(rendered).to start_with("\e[36m")
  end
end
