# frozen_string_literal: true

RSpec.describe Charming::Components::Viewport do
  it "renders content unchanged without dimensions" do
    viewport = described_class.new(content: "One\nTwo")

    expect(viewport.render).to eq("One\nTwo")
  end

  it "clips content vertically using an offset and height" do
    viewport = described_class.new(content: "One\nTwo\nThree", offset: 1, height: 2)

    expect(viewport.render).to eq("Two\nThree")
  end

  it "pads missing vertical space when height exceeds content" do
    viewport = described_class.new(content: "One", height: 3)

    expect(viewport.render).to eq("One\n\n")
  end

  it "clips and pads content horizontally" do
    viewport = described_class.new(content: "abcdef", width: 3, column: 2)

    expect(viewport.render).to eq("cde")
  end

  it "uses Unicode display width when clipping" do
    viewport = described_class.new(content: "a界b", width: 3)

    expect(viewport.render).to eq("a界")
  end

  it "preserves ANSI styling around clipped content" do
    viewport = described_class.new(content: "\e[31mabcdef\e[0m", width: 3)

    expect(viewport.render).to eq("\e[31mabc\e[0m")
  end

  it "renders component content" do
    component = Class.new(Charming::Component) do
      def render = "Component body"
    end

    viewport = described_class.new(content: component.new, width: 9)

    expect(viewport.render).to eq("Component")
  end
end
