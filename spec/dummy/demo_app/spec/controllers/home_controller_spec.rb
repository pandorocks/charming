# frozen_string_literal: true

require "demo_app"

RSpec.describe DemoApp::HomeController do
  let(:application) { DemoApp::Application.new }

  subject(:controller) { described_class.new(application: application) }

  describe "#show" do
    it "renders the view with the model" do
      response = controller.dispatch(:show)

      expect(response).to respond_to(:body)
    end
  end

  describe "#refresh" do
    it "renders loading state and queues an async task" do
      executor = Class.new do
        attr_reader :name

        def submit(name, &)
          @name = name
          nil
        end
      end.new
      application.task_executor = executor

      response = controller.dispatch(:refresh)

      expect(executor.name).to eq(:refresh_home)
      expect(response.body).to include("Status: Loading")
    end
  end

  describe "#refresh_loaded" do
    it "renders the completed async task result" do
      response = described_class.new(
        application: application,
        event: Charming::TaskEvent.new(name: :refresh_home, value: "Done")
      ).dispatch_task

      expect(response.body).to include("Status: Loaded")
      expect(response.body).to include("Done")
    end
  end
end
