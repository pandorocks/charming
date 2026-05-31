# Testing

Charming is designed to be tested without a real terminal. Use controller/view/component specs for small units and `MemoryBackend` for runtime-level behavior.

## Generated Specs

Generated apps include specs for the default model, controller, view, and component. Run them from the generated app with:

```sh
bundle exec rspec
```

Framework development uses:

```sh
bin/rspec
bin/lint
bin/check
```

## Controller Specs

Instantiate controllers with an application and dispatch actions directly:

```ruby
RSpec.describe WeatherTui::HomeController do
  let(:application) { WeatherTui::Application.new }

  it "renders the home screen" do
    response = described_class.new(application: application).dispatch(:show)

    expect(response.body).to include("Weather")
  end
end
```

Pass events when testing key, timer, task, or mouse dispatch:

```ruby
event = Charming::KeyEvent.new(key: :up)
response = described_class.new(application: application, event: event).dispatch_key
```

Route params can be passed directly for controller-level tests:

```ruby
controller = described_class.new(application: application, params: {id: "123"})
expect(controller.dispatch(:show).body).to include("123")
```

## View Specs

Views are plain objects. Pass assigns to `new` and call `render`:

```ruby
view = WeatherTui::HomeView.new(
  home: double(title: "Weather"),
  theme: Charming::UI::Theme.default
)

expect(view.render).to include("Weather")
```

Use `Charming::UI::Width.strip_ansi` when assertions do not need ANSI escape codes:

```ruby
body = Charming::UI::Width.strip_ansi(view.render)
expect(body).to include("Weather")
```

## Component Specs

Render components directly:

```ruby
component = Charming::Components::List.new(items: %w[One Two])

expect(component.render).to include("One")
```

For interactive components, assert return values and state changes:

```ruby
input = Charming::Components::TextInput.new

expect(input.handle_key(Charming::KeyEvent.new(key: :a, char: "a"))).to eq(:handled)
expect(input.value).to eq("a")
```

## Runtime Specs

Use `MemoryBackend` to script terminal events and capture rendered frames:

```ruby
backend = Charming::Internal::Terminal::MemoryBackend.new(
  events: [
    Charming::KeyEvent.new(key: :up),
    Charming::KeyEvent.new(key: :q)
  ]
)

Charming::Runtime.new(WeatherTui::Application.new, backend: backend).run

expect(backend.frames).to include("Count: 1")
```

`MemoryBackend` also accepts dimensions:

```ruby
backend = Charming::Internal::Terminal::MemoryBackend.new(width: 100, height: 40)
```

## Timer Specs

Inject a deterministic clock into the runtime:

```ruby
times = [0.0, 0.0, 0.0, 0.1, 0.2]
clock = -> { times.shift || 0.2 }

runtime = Charming::Runtime.new(app, backend: backend, clock: clock)
runtime.run
```

This avoids sleeps and makes timer behavior deterministic.

## Task Specs

Use the inline task executor for deterministic async task tests:

```ruby
runtime = Charming::Runtime.new(
  app,
  backend: backend,
  task_executor: Charming::TaskExecutor::Inline
)
runtime.run
```

Controller-level task tests can stub the app task executor:

```ruby
executor = Class.new do
  attr_reader :name

  def submit(name, &)
    @name = name
  end
end.new

application.task_executor = executor
controller.dispatch(:refresh)

expect(executor.name).to eq(:refresh_home)
```

## Snapshot-Style Assertions

For rendered terminal output, prefer small, stable assertions first. Use full-frame comparisons when the output is intentionally fixed.

Good:

```ruby
body = Charming::UI::Width.strip_ansi(response.body)
expect(body).to include("Status: Loaded")
```

Use exact frame assertions for runtime flow:

```ruby
expect(backend.frames).to eq(["Home", "Settings"])
```

Avoid tests that only assert a response exists unless the behavior under test is dispatch plumbing.
