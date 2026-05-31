# frozen_string_literal: true

RSpec.describe Charming::Components::Markdown do
  def strip_ansi(value)
    Charming::UI::Width.strip_ansi(value)
  end

  it "renders markdown content as a component" do
    component = described_class.new(content: "# Hello\n\nWelcome to **Charming**.", width: 30)

    expect(strip_ansi(component.render)).to eq("Hello\n\nWelcome to Charming.")
  end

  it "can be used as viewport content" do
    component = described_class.new(content: "One\n\nTwo\n\nThree")
    viewport = Charming::Components::Viewport.new(content: component, height: 3)

    expect(strip_ansi(viewport.render)).to eq("One\n\nTwo")
  end
end
