# frozen_string_literal: true

RSpec.describe Charming::Router do
  before do
    stub_const("RouterSpecController", Class.new(Charming::Controller))
  end

  it "resolves Rails-like controller actions" do
    router = described_class.new

    router.draw do
      root "router_spec#show"
    end

    route = router.resolve("/")

    expect(route.controller_class).to eq(RouterSpecController)
    expect(route.action).to eq(:show)
  end

  it "resolves controller actions inside a namespace" do
    stub_const("RouterSpecApp", Module.new)
    stub_const("RouterSpecApp::HomeController", Class.new(Charming::Controller))
    router = described_class.new(namespace: "RouterSpecApp")

    router.draw do
      root "home#show"
    end

    route = router.resolve("/")

    expect(route.controller_class).to eq(RouterSpecApp::HomeController)
    expect(route.action).to eq(:show)
  end
end
