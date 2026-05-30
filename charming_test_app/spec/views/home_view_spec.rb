# frozen_string_literal: true

require "charming_test_app"

RSpec.describe CharmingTestApp::HomeView do
  describe "#render" do
    it "renders the model title" do
      view = described_class.new(
         home: double(title: "CharmingTestApp")
       )

      expect(view.render).to eq("CharmingTestApp")
    end
  end
end
