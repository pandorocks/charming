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

  it "renders view objects" do
    view = Class.new(Charming::View) do
      def render
        "Rendered from view"
      end
    end
    controller = Class.new(described_class) do
      define_method(:show) do
        render view.new
      end
    end

    response = controller.new(application: application).dispatch(:show)

    expect(response.body).to eq("Rendered from view")
  end

  # Locks in the duck-typed dispatch at controller.rb:50 — `body.render` is
  # invoked, not `body.to_s`. Without distinct return values a refactor to
  # `body.to_s` would silently pass identical-output tests.
  it "invokes #render on a renderable body rather than falling back to #to_s" do
    renderable = Class.new do
      def render = "from-render"
      def to_s = "from-to_s"
    end
    controller = Class.new(described_class) do
      define_method(:show) do
        render renderable.new
      end
    end

    response = controller.new(application: application).dispatch(:show)

    expect(response.body).to eq("from-render")
  end

  it "falls back to #to_s when the body does not respond to #render" do
    non_renderable = Object.new
    def non_renderable.to_s = "from-to_s-fallback"
    controller = Class.new(described_class) do
      define_method(:show) { render(non_renderable) }
    end

    response = controller.new(application: application).dispatch(:show)

    expect(response.body).to eq("from-to_s-fallback")
  end

  it "stores models in application session across controller instances" do
    counter_model = Class.new(Charming::ApplicationModel) do
      attribute :count, :integer, default: 0
    end
    controller = Class.new(described_class) do
      define_method(:show) do
        counter = model(:counter, counter_model)
        counter.count += 1
        render "Count: #{counter.count}"
      end
    end

    controller.new(application: application).dispatch(:show)
    response = controller.new(application: application).dispatch(:show)

    expect(response.body).to eq("Count: 2")
  end

  it "stores separate model instances for separate keys" do
    model_class = Class.new(Charming::ApplicationModel)
    controller = described_class.new(application: application)

    first = controller.model(:first, model_class)
    second = controller.model(:second, model_class)

    expect(first).not_to equal(second)
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
