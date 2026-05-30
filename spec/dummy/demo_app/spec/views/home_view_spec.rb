# frozen_string_literal: true

require "demo_app"

RSpec.describe DemoApp::HomeView do
  describe "#render" do
    it "renders the model title" do
      view = described_class.new(
        home: double(title: "DemoApp", status: "Idle", message: "Ready")
      )

      expect(view.render).to include("DemoApp")
      expect(view.render).to include("Status: Idle")
    end
  end
end
