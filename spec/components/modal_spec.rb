# frozen_string_literal: true

RSpec.describe Charming::Components::Modal do
  it "renders a framed modal around string content" do
    modal = described_class.new(content: "Body", title: "Title", help: "Help", width: 20)

    expect(modal.render).to include("Title")
    expect(modal.render).to include("Help")
    expect(modal.render).to include("Body")
    expect(modal.render).to include("╔")
  end

  it "renders component content" do
    content = Class.new(Charming::Component) do
      def render = "Component body"
    end

    modal = described_class.new(content: content.new)

    expect(modal.render).to include("Component body")
  end
end
