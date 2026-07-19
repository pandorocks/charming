# frozen_string_literal: true

RSpec.describe Charming::Components::Modal do
  it "renders a framed modal around string content" do
    modal = described_class.new(content: "Body", title: "Title", help: "Help", width: 20)

    expect(modal.render).to include("Title")
    expect(modal.render).to include("Help")
    expect(modal.render).to include("Body")
    expect(modal.render).to include("╭")
  end

  it "renders help as a footer line below the body" do
    modal = described_class.new(content: "Body", title: "Title", help: "Help", width: 20)

    rendered = modal.render
    expect(rendered.index("Title")).to be < rendered.index("Body")
    expect(rendered.index("Body")).to be < rendered.index("Help")
  end

  it "styles the default border without coloring body content as border" do
    modal = described_class.new(content: "Body", width: 20)

    expect(modal.render).to include("\e[38;2;255;179;71;48;2;17;26;44m╭")
    expect(modal.render).not_to include("\e[38;2;255;179;71;48;2;17;26;44mBody")
  end

  it "renders component content" do
    content = Class.new(Charming::Component) do
      def render = "Component body"
    end

    modal = described_class.new(content: content.new)

    expect(modal.render).to include("Component body")
  end
end
