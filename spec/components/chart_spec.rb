# frozen_string_literal: true

RSpec.describe Charming::Components::Chart do
  describe "line mode" do
    it "renders to the declared cell box" do
      rendered = described_class.new(series: [0, 1, 2, 3, 2, 1, 0], width: 6, height: 3).render
      lines = rendered.lines(chomp: true)

      expect(lines.length).to eq(3)
      lines.each { |line| expect(Charming::UI::Width.measure(line)).to eq(6) }
    end

    it "draws braille glyphs" do
      rendered = described_class.new(series: [0, 3, 0, 3], width: 4, height: 2).render

      expect(rendered).to match(/[⠀-⣿]/)
    end
  end

  describe "bar mode" do
    it "renders to the declared cell box" do
      rendered = described_class.new(series: [1, 2, 3, 4], width: 4, height: 3, kind: :bar).render
      lines = rendered.lines(chomp: true)

      expect(lines.length).to eq(3)
      lines.each { |line| expect(Charming::UI::Width.measure(line)).to eq(4) }
    end

    it "fills the tallest bar to the bottom and leaves the shortest empty" do
      rendered = described_class.new(series: [0, 8], width: 2, height: 1, kind: :bar).render

      expect(rendered).to eq(" █") # baseline 0: first column empty, second full
    end
  end

  it "renders an empty series as an empty string" do
    expect(described_class.new(series: [], width: 4, height: 2).render).to eq("")
  end
end
