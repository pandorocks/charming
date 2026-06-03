# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe DemoApp::Lg::ShowView do
  describe "#render" do
    it "renders a lazygit-structured layout" do
      view = described_class.new(
        screen: Charming::Screen.new(width: 90, height: 24),
        theme: DemoApp::Application.new.theme
      )

      output = Charming::UI::Width.strip_ansi(view.render)

      expect(output).to include("Working Tree")
      expect(output).to include("Files")
      expect(output).to include("Recent Commits")
      expect(output).to include("Diff")
      expect(output).to include("p commands")
    end

    it "aligns left and right pane row boundaries" do
      view = described_class.new(
        screen: Charming::Screen.new(width: 90, height: 24),
        theme: DemoApp::Application.new.theme
      )

      lines = Charming::UI::Width.strip_ansi(view.render).lines(chomp: true)
      top_row_bottom = lines.find { |line| line.include?("╰") && line.scan("╰").length == 2 }

      expect(top_row_bottom).to eq("╰──────────────────────────────╯ ╰───────────────────────────────────────────────────────╯")
    end
  end
end
