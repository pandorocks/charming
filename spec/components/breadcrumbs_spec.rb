# frozen_string_literal: true

RSpec.describe Charming::Components::Breadcrumbs do
  it "joins items with the separator" do
    crumbs = described_class.new(items: ["Home", "Projects", "My App"])
    plain = Charming::UI::Width.strip_ansi(crumbs.render)
    expect(plain).to eq("Home › Projects › My App")
  end

  it "renders empty string for no items" do
    expect(described_class.new(items: []).render).to eq("")
  end

  it "renders a single item highlighted" do
    crumbs = described_class.new(items: ["Home"])
    plain = Charming::UI::Width.strip_ansi(crumbs.render)
    expect(plain).to eq("Home")
  end

  it "accepts a custom separator" do
    crumbs = described_class.new(items: %w[a b], separator: " > ")
    expect(Charming::UI::Width.strip_ansi(crumbs.render)).to eq("a > b")
  end
end
