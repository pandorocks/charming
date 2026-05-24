# frozen_string_literal: true

RSpec.describe Charming::Controller do
  let(:application) { Charming::Application.new }

  before do
    stub_const("ControllerSpecController", controller_class)
  end

  let(:controller_class) do
    Class.new(described_class) do
      key "up", :increment
      key "q", :quit

      def show
        session[:count] ||= 0
        render "Count: #{session[:count]}"
      end

      def increment
        session[:count] += 1
        render "Count: #{session[:count]}"
      end
    end
  end

  it "renders action responses" do
    response = ControllerSpecController.new(application: application).dispatch(:show)

    expect(response.body).to eq("Count: 0")
  end

  it "dispatches key bindings to actions" do
    ControllerSpecController.new(application: application).dispatch(:show)

    response = ControllerSpecController.new(
      application: application,
      event: Charming::KeyEvent.new(key: :up)
    ).dispatch_key

    expect(response.body).to eq("Count: 1")
  end

  it "returns a quit response from controller actions" do
    response = ControllerSpecController.new(
      application: application,
      event: Charming::KeyEvent.new(key: :q)
    ).dispatch_key

    expect(response).to be_quit
  end
end
