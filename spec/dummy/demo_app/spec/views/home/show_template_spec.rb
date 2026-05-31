# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "home/show template" do
  describe "#render" do
    it "renders the model title" do
      template = Charming::Templates.resolve("home/show", root: DemoApp::Application.root)
      view = Charming::TemplateView.new(
        template: template,
        namespace: DemoApp,
        home: double(title: "DemoApp", status: "Idle", progress: 0, activity_index: 0, message: "Ready"),
        theme: DemoApp::Application.new.theme
      )

      expect(view.render).to include("DemoApp")
      expect(view.render).to include("Status: Idle")
    end
  end
end
