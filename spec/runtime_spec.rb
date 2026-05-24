# frozen_string_literal: true

RSpec.describe Charming::Runtime do
  before do
    stub_const("RuntimeSpecController", controller_class)
    stub_const("RuntimeSpecApp", app_class)
  end

  let(:controller_class) do
    Class.new(Charming::Controller) do
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

  let(:app_class) do
    Class.new(Charming::Application) do
      routes do
        root "runtime_spec#show"
      end
    end
  end

  it "renders the root action and key-dispatched actions" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :up),
        Charming::KeyEvent.new(key: :q)
      ]
    )

    described_class.new(RuntimeSpecApp.new, backend: backend).run

    expect(backend.frames).to eq(["Count: 0", "Count: 1"])
  end

  it "passes backend screen dimensions to controllers" do
    screen_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "#{screen.width}x#{screen.height}"
      end
    end
    stub_const("ScreenRuntimeSpecController", screen_controller)
    screen_app = Class.new(Charming::Application) do
      routes do
        root "screen_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)],
      width: 100,
      height: 40
    )

    described_class.new(screen_app.new, backend: backend).run

    expect(backend.frames).to eq(["100x40"])
  end

  it "restores terminal state when a controller raises" do
    failing_controller = Class.new(Charming::Controller) do
      def show
        raise "boom"
      end
    end
    stub_const("FailingRuntimeSpecController", failing_controller)
    failing_app = Class.new(Charming::Application) do
      routes do
        root "failing_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new

    expect { described_class.new(failing_app.new, backend: backend).run }.to raise_error("boom")
    expect(backend.operations).to include(:show_cursor, :leave_alt_screen)
  end
end
