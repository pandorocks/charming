# frozen_string_literal: true

RSpec.describe "Charming::Runtime error screen" do
  before do
    stub_const("ErrorScreenSpecController", controller_class)
    stub_const("ErrorScreenSpecApp", app_class)
  end

  let(:controller_class) do
    Class.new(Charming::Controller) do
      key "x", :explode
      key "q", :quit

      def show
        session[:visits] = session.fetch(:visits, 0) + 1
        render "Visits: #{session[:visits]}"
      end

      def explode
        raise "kaboom from action"
      end
    end
  end

  let(:app_class) do
    Class.new(Charming::Application) do
      routes do
        root "error_screen_spec#show"
      end
    end
  end

  def run_with_events(events)
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: events)
    Charming::Runtime.new(ErrorScreenSpecApp.new, backend: backend).run
    backend
  end

  it "renders an error panel instead of crashing when an action raises" do
    backend = run_with_events([
      Charming::Events::KeyEvent.new(key: :x),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    error_frame = backend.frames[1]
    expect(error_frame).to include("RuntimeError")
    expect(error_frame).to include("kaboom from action")
    expect(error_frame).to include("press any key to continue")
  end

  it "quits from the error screen on q" do
    backend = run_with_events([
      Charming::Events::KeyEvent.new(key: :x),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    # Two frames: initial render + error panel. q quits without further frames.
    expect(backend.frames.length).to eq(2)
  end

  it "dismisses the error screen and re-renders the route on any other key" do
    backend = run_with_events([
      Charming::Events::KeyEvent.new(key: :x),
      Charming::Events::KeyEvent.new(key: :enter),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    expect(backend.frames.last).to include("Visits: 2")
  end

  it "ignores timer and task events while the error screen is showing" do
    backend = run_with_events([
      Charming::Events::KeyEvent.new(key: :x),
      Charming::Events::TimerEvent.new(name: :tick, now: 0.0),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    # Timer event must not dismiss the panel or add frames.
    expect(backend.frames.length).to eq(2)
  end

  it "shows an error panel when the initial action raises" do
    broken_controller = Class.new(Charming::Controller) do
      def show
        raise ArgumentError, "broken at boot"
      end
    end
    stub_const("BrokenBootController", broken_controller)
    broken_app = Class.new(Charming::Application) do
      routes do
        root "broken_boot#show"
      end
    end
    stub_const("BrokenBootApp", broken_app)

    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::Events::KeyEvent.new(key: :q)]
    )
    Charming::Runtime.new(BrokenBootApp.new, backend: backend).run

    expect(backend.frames.first).to include("ArgumentError")
    expect(backend.frames.first).to include("broken at boot")
  end

  it "logs the error with backtrace to the application logger" do
    log_output = StringIO.new
    app = ErrorScreenSpecApp.new
    app.logger = Logger.new(log_output)

    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [
      Charming::Events::KeyEvent.new(key: :x),
      Charming::Events::KeyEvent.new(key: :q)
    ])
    Charming::Runtime.new(app, backend: backend).run

    expect(log_output.string).to include("RuntimeError: kaboom from action")
  end
end
