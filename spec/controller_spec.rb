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

  describe ".key_bindings inheritance" do
    it "inherits a copy of parent bindings, not a live reference" do
      parent = Class.new(described_class) { key "up", :foo }
      child = Class.new(parent) { key "down", :bar }

      expect(child.key_bindings).to eq("up" => :foo, "down" => :bar)
      expect(parent.key_bindings).to eq("up" => :foo)
      expect(child.key_bindings).not_to equal(parent.key_bindings)
    end

    it "isolates siblings so adding a key to one does not leak to the other" do
      parent   = Class.new(described_class) { key "shared", :shared_action }
      sibling1 = Class.new(parent)          { key "one", :one_action }
      sibling2 = Class.new(parent)          { key "two", :two_action }

      expect(sibling1.key_bindings).to eq("shared" => :shared_action, "one" => :one_action)
      expect(sibling2.key_bindings).to eq("shared" => :shared_action, "two" => :two_action)
    end

    it "cumulates bindings across a three-level chain" do
      grandparent = Class.new(described_class) { key "g", :grand }
      parent      = Class.new(grandparent)     { key "p", :parent }
      child       = Class.new(parent)          { key "c", :child }

      expect(child.key_bindings).to eq("g" => :grand, "p" => :parent, "c" => :child)
    end

    # Snapshot is taken on first read of #key_bindings (which the `key` class
    # macro triggers). Additions to the parent after that point are not visible
    # in the child — locking in this Rails-style inheritance contract.
    it "does not propagate parent additions made after the child has snapshotted" do
      parent = Class.new(described_class) { key "up", :foo }
      child  = Class.new(parent)          { key "down", :bar }

      parent.key "q", :quit

      expect(parent.key_bindings).to include("q" => :quit)
      expect(child.key_bindings).not_to have_key("q")
    end
  end
end
