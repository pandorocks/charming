# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DemoApp::AppFrameComponent do
  describe "#render" do
    it "returns a string" do
      component = described_class.new(
        title: "DemoApp",
        status: "Idle",
        progress: 0,
        activity_index: 0,
        message: "Ready"
      )

      expect(component.render).to be_a(String)
    end

    it "renders visible progress while loading" do
      component = described_class.new(
        title: "DemoApp",
        status: "Loading",
        progress: 3,
        activity_index: 0,
        message: "Working"
      )

      output = Charming::UI::Width.strip_ansi(component.render)
      expect(output).to include("[===                             ] Working")
      expect(output).to include("f27^_E#cB4A&8F0d$5C+b=3@&AF89*@3 Working.")
    end

    it "renders the markdown preview" do
      component = described_class.new(
        title: "DemoApp",
        status: "Idle",
        progress: 0,
        activity_index: 0,
        message: "Ready"
      )

      output = Charming::UI::Width.strip_ansi(component.render)
      expect(output).to include("Markdown Preview")
      expect(output).to include("Charming renders Markdown with Kramdown and")
      expect(output).to include("Rouge:")
      expect(output).to include("render_component Charming::Components::Markdown.new")
    end
  end
end
