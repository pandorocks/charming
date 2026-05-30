# frozen_string_literal: true

require "demo_app"

RSpec.describe DemoApp::HomeView do
  describe "#render" do
    it "renders the model title" do
      view = described_class.new(
         home: double(title: "DemoApp")
       )

      expect(view.render).to eq("DemoApp")
    end
  end
end
