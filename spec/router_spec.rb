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
    expect(route.params).to eq({})
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

  it "resolves nested controller paths inside a namespace" do
    stub_const("RouterSpecApp", Module.new)
    stub_const("RouterSpecApp::Admin", Module.new)
    stub_const("RouterSpecApp::Admin::UsersController", Class.new(Charming::Controller))
    router = described_class.new(namespace: "RouterSpecApp")

    router.draw do
      screen "/admin/users", to: "admin/users#show"
    end

    route = router.resolve("/admin/users")

    expect(route.controller_class).to eq(RouterSpecApp::Admin::UsersController)
    expect(route.action).to eq(:show)
  end

  it "resolves dynamic route params with symbol keys" do
    router = described_class.new

    router.draw do
      screen "/users/:id", to: "router_spec#show"
    end

    route = router.resolve("/users/123")

    expect(route.controller_class).to eq(RouterSpecController)
    expect(route.action).to eq(:show)
    expect(route.params).to eq(id: "123")
  end

  it "resolves multiple dynamic route params" do
    router = described_class.new

    router.draw do
      screen "/users/:user_id/posts/:id", to: "router_spec#show"
    end

    route = router.resolve("/users/42/posts/7")

    expect(route.params).to eq(user_id: "42", id: "7")
  end

  it "URL-decodes dynamic route params" do
    router = described_class.new

    router.draw do
      screen "/users/:name", to: "router_spec#show"
    end

    route = router.resolve("/users/Jane+Doe")

    expect(route.params).to eq(name: "Jane Doe")
  end

  it "prefers exact routes over dynamic routes" do
    router = described_class.new

    router.draw do
      screen "/users/:id", to: "router_spec#show"
      screen "/users/new", to: "router_spec#new"
    end

    route = router.resolve("/users/new")

    expect(route.action).to eq(:new)
    expect(route.params).to eq({})
  end

  it "does not partially match extra path segments" do
    router = described_class.new

    router.draw do
      screen "/users/:id", to: "router_spec#show"
    end

    expect { router.resolve("/users/123/edit") }.to raise_error(KeyError)
  end

  it "does not match missing dynamic segments" do
    router = described_class.new

    router.draw do
      screen "/users/:id", to: "router_spec#show"
    end

    expect { router.resolve("/users") }.to raise_error(KeyError)
  end
end
