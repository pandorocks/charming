# frozen_string_literal: true

RSpec.describe Charming do
  it "has a version number" do
    expect(Charming::VERSION).not_to be_nil
  end

  it "exposes presentation APIs without the presentation namespace" do
    expect(described_class.const_defined?(:Presentation, false)).to be(false)
    expect(Charming::View).to be_a(Class)
    expect(Charming::Component).to be_a(Class)
    expect(Charming::UI::Border).to be_a(Class)
    expect(Charming::Components::List).to be_a(Class)
    expect(Charming::Layout::Rect).to be_a(Class)
    expect(Charming::Markdown::Renderer).to be_a(Class)
  end
end
