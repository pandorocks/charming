# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe DemoApp::Home::ShowView do
  describe "#render" do
    it "renders the model title" do
      view = described_class.new(
        home: home_double(message: "Ready"),
        theme: DemoApp::Application.new.theme
      )

      expect(view.render).to include("DemoApp")
      expect(view.render).to include("Status: Idle")
      expect(Charming::Presentation::UI::Width.strip_ansi(view.render)).to include("Markdown Preview")
    end

    it "renders visible progress while loading" do
      view = described_class.new(
        home: home_double(status: "Loading", progress: 3, message: "Working"),
        theme: DemoApp::Application.new.theme
      )

      output = Charming::Presentation::UI::Width.strip_ansi(view.render)
      expect(output).to include("[===                             ] Working")
      expect(output).to include("f27^_E#cB4A&8F0d$5C+b=3@&AF89*@3 Working.")
    end

    it "renders the markdown preview" do
      view = described_class.new(
        home: home_double(message: "Ready"),
        theme: DemoApp::Application.new.theme
      )

      output = Charming::Presentation::UI::Width.strip_ansi(view.render)
      expect(output).to include("Markdown Preview")
      expect(output).to include("Charming renders Markdown with Kramdown and")
      expect(output).to include("Rouge:")
      expect(output).to include("render_component Charming::Presentation::Components::Markdown.new")
    end
  end

  def home_double(message:, status: "Idle", progress: 0, activity_index: 0)
    double(
      title: "DemoApp",
      status: status,
      progress: progress,
      activity_index: activity_index,
      message: message
    )
  end
end
