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
        Charming::Events::KeyEvent.new(key: :up),
        Charming::Events::KeyEvent.new(key: :q)
      ]
    )

    described_class.new(RuntimeSpecApp.new, backend: backend).run

    expect(backend.frames).to eq(["Count: 0", "Count: 1"])
  end

  it "keeps raw input active while rendering and reading events" do
    raw_backend = Class.new(Charming::Internal::Terminal::MemoryBackend) do
      attr_reader :raw_events

      def initialize(**)
        super
        @raw_input_active = false
        @raw_events = []
      end

      def with_raw_input
        @raw_events << :entered
        @raw_input_active = true
        yield
      ensure
        @raw_input_active = false
        @raw_events << :left
      end

      def write_frame(frame)
        @raw_events << [:write_frame, @raw_input_active]
        super
      end

      def read_event(timeout: nil)
        @raw_events << [:read_event, @raw_input_active]
        super
      end
    end
    backend = raw_backend.new(events: [Charming::Events::KeyEvent.new(key: :q)])

    described_class.new(RuntimeSpecApp.new, backend: backend).run

    expect(backend.raw_events).to include(:entered, [:write_frame, true], [:read_event, true], :left)
  end

  it "enables and disables mouse tracking around the run loop" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::Events::KeyEvent.new(key: :q)]
    )

    described_class.new(RuntimeSpecApp.new, backend: backend).run

    expect(backend.operations).to include(:enable_mouse_tracking, :disable_mouse_tracking)
    expect(backend.mouse_enabled?).to be(false)
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
      events: [Charming::Events::KeyEvent.new(key: :q)],
      width: 100,
      height: 40
    )

    described_class.new(screen_app.new, backend: backend).run

    expect(backend.frames).to eq(["100x40"])
  end

  it "re-renders the current route after resize events" do
    screen_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "#{screen.width}x#{screen.height}"
      end
    end
    stub_const("ResizeRuntimeSpecController", screen_controller)
    screen_app = Class.new(Charming::Application) do
      routes do
        root "resize_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::ResizeEvent.new(width: 100, height: 40),
        Charming::Events::KeyEvent.new(key: :q)
      ],
      width: 80,
      height: 24
    )

    described_class.new(screen_app.new, backend: backend).run

    expect(backend.frames).to eq(%w[80x24 100x40])
  end

  it "clears and full-repaints after resize instead of overlaying a sparse diff" do
    screen_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "#{screen.width}x#{screen.height}"
      end
    end
    stub_const("ResizeInvalidateRuntimeSpecController", screen_controller)
    screen_app = Class.new(Charming::Application) do
      routes do
        root "resize_invalidate_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::ResizeEvent.new(width: 100, height: 40),
        Charming::Events::KeyEvent.new(key: :q)
      ],
      width: 80,
      height: 24
    )

    described_class.new(screen_app.new, backend: backend).run

    write_ops = backend.operations.select { |op| op.is_a?(Array) && %i[write_frame write_lines].include?(op.first) }
    expect(write_ops).to eq([[:write_frame, "80x24"], [:write_frame, "100x40"]])
    expect(backend.operations.count(:clear)).to eq(3)
  end

  it "navigates to routed screens" do
    home_controller = Class.new(Charming::Controller) do
      key "s", :settings

      def show
        render "Home"
      end

      def settings
        navigate_to "/settings"
      end
    end
    settings_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "Settings"
      end
    end
    stub_const("NavigationRuntimeSpecHomeController", home_controller)
    stub_const("NavigationRuntimeSpecSettingsController", settings_controller)
    navigation_app = Class.new(Charming::Application) do
      routes do
        root "navigation_runtime_spec_home#show"
        screen "/settings", to: "navigation_runtime_spec_settings#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::KeyEvent.new(key: :s),
        Charming::Events::KeyEvent.new(key: :q)
      ]
    )

    described_class.new(navigation_app.new, backend: backend).run

    expect(backend.frames).to eq(%w[Home Settings])
  end

  it "passes dynamic route params to navigated controllers" do
    home_controller = Class.new(Charming::Controller) do
      key "u", :user

      def show
        render "Home"
      end

      def user
        navigate_to "/users/123"
      end
    end
    user_controller = Class.new(Charming::Controller) do
      key "r", :refresh
      key "q", :quit

      def show
        render "User: #{params[:id]}"
      end

      def refresh
        render "Refresh: #{params[:id]}"
      end
    end
    stub_const("ParamRuntimeSpecHomeController", home_controller)
    stub_const("ParamRuntimeSpecUsersController", user_controller)
    param_app = Class.new(Charming::Application) do
      routes do
        root "param_runtime_spec_home#show"
        screen "/users/:id", to: "param_runtime_spec_users#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::KeyEvent.new(key: :u),
        Charming::Events::KeyEvent.new(key: :r),
        Charming::Events::KeyEvent.new(key: :q)
      ]
    )

    described_class.new(param_app.new, backend: backend).run

    expect(backend.frames).to eq(["Home", "User: 123", "Refresh: 123"])
  end

  it "re-renders the navigated route after resize events" do
    home_controller = Class.new(Charming::Controller) do
      key "s", :settings

      def show
        render "Home"
      end

      def settings
        navigate_to "/settings"
      end
    end
    settings_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "Settings: #{screen.width}x#{screen.height}"
      end
    end
    stub_const("ResizeNavigationRuntimeSpecHomeController", home_controller)
    stub_const("ResizeNavigationRuntimeSpecSettingsController", settings_controller)
    navigation_app = Class.new(Charming::Application) do
      routes do
        root "resize_navigation_runtime_spec_home#show"
        screen "/settings", to: "resize_navigation_runtime_spec_settings#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::KeyEvent.new(key: :s),
        Charming::Events::ResizeEvent.new(width: 100, height: 40),
        Charming::Events::KeyEvent.new(key: :q)
      ],
      width: 80,
      height: 24
    )

    described_class.new(navigation_app.new, backend: backend).run

    expect(backend.frames).to eq(["Home", "Settings: 80x24", "Settings: 100x40"])
  end

  it "dispatches due timer events without backend input" do
    timer_controller = Class.new(Charming::Controller) do
      key "q", :quit
      timer :clock, every: 0.1, action: :tick

      def show
        session[:ticks] ||= 0
        render "Ticks: #{session[:ticks]}"
      end

      def tick
        session[:ticks] += 1
        render "Ticks: #{session[:ticks]}"
      end
    end
    stub_const("TimerRuntimeSpecController", timer_controller)
    timer_app = Class.new(Charming::Application) do
      routes do
        root "timer_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [nil, Charming::Events::KeyEvent.new(key: :q)]
    )
    times = [0.0, 0.0, 0.0, 0.1, 0.2]
    clock = -> { times.shift || 0.2 }

    described_class.new(timer_app.new, backend: backend, clock: clock).run

    expect(backend.frames).to eq(["Ticks: 0", "Ticks: 1"])
  end

  it "does not repaint unchanged timer frames" do
    timer_controller = Class.new(Charming::Controller) do
      key "q", :quit
      timer :clock, every: 0.1, action: :tick

      def show
        render "Still"
      end

      def tick
        render "Still"
      end
    end
    stub_const("UnchangedTimerRuntimeSpecController", timer_controller)
    timer_app = Class.new(Charming::Application) do
      routes do
        root "unchanged_timer_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [nil, Charming::Events::KeyEvent.new(key: :q)]
    )
    times = [0.0, 0.0, 0.0, 0.1, 0.2, 0.2, 0.2]
    clock = -> { times.shift || 0.2 }

    described_class.new(timer_app.new, backend: backend, clock: clock).run

    expect(backend.frames).to eq(["Still"])
  end

  it "caps backend reads at the default timeout when timers are later" do
    timer_controller = Class.new(Charming::Controller) do
      key "q", :quit
      timer :clock, every: 10.0, action: :tick

      def show
        render "Waiting"
      end

      def tick
        render "Tick"
      end
    end
    stub_const("ReadTimeoutRuntimeSpecController", timer_controller)
    timer_app = Class.new(Charming::Application) do
      routes do
        root "read_timeout_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::Events::KeyEvent.new(key: :q)]
    )
    clock = -> { 0.0 }

    described_class.new(timer_app.new, backend: backend, clock: clock).run

    expect(backend.operations).to include([:read_event, described_class::DEFAULT_READ_TIMEOUT])
  end

  it "dispatches inline task results before backend input" do
    task_controller = Class.new(Charming::Controller) do
      key "q", :quit
      on_task :fetch, action: :loaded

      def show
        unless session[:started]
          session[:started] = true
          run_task(:fetch) { "feed" }
        end
        render "Loading"
      end

      def loaded
        render "Loaded: #{event.value}"
      end
    end
    stub_const("InlineTaskRuntimeSpecController", task_controller)
    task_app = Class.new(Charming::Application) do
      routes do
        root "inline_task_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [nil, Charming::Events::KeyEvent.new(key: :q)]
    )

    described_class.new(task_app.new, backend: backend, task_executor: Charming::Tasks::InlineExecutor).run

    expect(backend.frames).to eq(["Loading", "Loaded: feed"])
  end

  it "renders task errors and continues dispatching keys" do
    task_controller = Class.new(Charming::Controller) do
      key "up", :moved
      key "q", :quit
      on_task :fetch, action: :loaded

      def show
        unless session[:started]
          session[:started] = true
          run_task(:fetch) { raise "boom" }
        end
        render "Loading"
      end

      def loaded
        render "Error: #{event.error.message}"
      end

      def moved
        render "Key ok"
      end
    end
    stub_const("ErrorTaskRuntimeSpecController", task_controller)
    task_app = Class.new(Charming::Application) do
      routes do
        root "error_task_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [nil, Charming::Events::KeyEvent.new(key: :up), Charming::Events::KeyEvent.new(key: :q)]
    )

    described_class.new(task_app.new, backend: backend, task_executor: Charming::Tasks::InlineExecutor).run

    expect(backend.frames).to eq(["Loading", "Error: boom", "Key ok"])
  end

  it "drops task events that have no binding after navigation" do
    home_controller = Class.new(Charming::Controller) do
      key "s", :settings
      on_task :fetch, action: :loaded

      def show
        render "Home"
      end

      def settings
        navigate_to "/settings"
      end

      def loaded
        render "Loaded"
      end
    end
    settings_controller = Class.new(Charming::Controller) do
      key "q", :quit

      def show
        render "Settings"
      end
    end
    stub_const("StaleTaskRuntimeSpecHomeController", home_controller)
    stub_const("StaleTaskRuntimeSpecSettingsController", settings_controller)
    task_app = Class.new(Charming::Application) do
      routes do
        root "stale_task_runtime_spec_home#show"
        screen "/settings", to: "stale_task_runtime_spec_settings#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::Events::KeyEvent.new(key: :s),
        Charming::Events::TaskEvent.new(name: :fetch, value: "feed"),
        Charming::Events::KeyEvent.new(key: :q)
      ]
    )

    described_class.new(task_app.new, backend: backend).run

    expect(backend.frames).to eq(%w[Home Settings])
  end

  it "dispatches task events supplied by the backend" do
    task_controller = Class.new(Charming::Controller) do
      key "q", :quit
      on_task :fetch, action: :loaded

      def show
        render "Waiting"
      end

      def loaded
        render "Loaded: #{event.value}"
      end
    end
    stub_const("BackendTaskRuntimeSpecController", task_controller)
    task_app = Class.new(Charming::Application) do
      routes do
        root "backend_task_runtime_spec#show"
      end
    end
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::Events::TaskEvent.new(name: :fetch, value: "feed"), Charming::Events::KeyEvent.new(key: :q)]
    )

    described_class.new(task_app.new, backend: backend).run

    expect(backend.frames).to eq(["Waiting", "Loaded: feed"])
  end

  it "dispatches threaded task results within a few loop iterations" do
    task_controller = Class.new(Charming::Controller) do
      key "q", :quit
      on_task :fetch, action: :loaded

      def show
        unless session[:started]
          session[:started] = true
          run_task(:fetch) { "feed" }
        end
        render "Loading"
      end

      def loaded
        render "Loaded: #{event.value}"
      end
    end
    stub_const("ThreadedTaskRuntimeSpecController", task_controller)
    task_app = Class.new(Charming::Application) do
      routes do
        root "threaded_task_runtime_spec#show"
      end
    end
    yielding_backend = Class.new(Charming::Internal::Terminal::MemoryBackend) do
      def read_event(timeout: nil)
        Thread.pass
        super
      end
    end
    backend = yielding_backend.new(
      events: Array.new(20) + [Charming::Events::KeyEvent.new(key: :q)]
    )

    described_class.new(task_app.new, backend: backend).run

    expect(backend.frames).to include("Loaded: feed")
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
    raw_backend = Class.new(Charming::Internal::Terminal::MemoryBackend) do
      attr_reader :raw_events

      def initialize(**)
        super
        @raw_events = []
      end

      def with_raw_input
        @raw_events << :entered
        yield
      ensure
        @raw_events << :left
      end
    end
    backend = raw_backend.new

    expect { described_class.new(failing_app.new, backend: backend).run }.to raise_error("boom")
    expect(backend.raw_events).to eq(%i[entered left])
    expect(backend.operations).to include(:show_cursor, :leave_alt_screen)
  end
end
