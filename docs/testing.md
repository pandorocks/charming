# Testing

Charming is designed to be tested without a real terminal. Use controller, template, view, and component specs for small units, and use `MemoryBackend` for runtime-level behavior.

For app structure and rendering concepts, see [Core Concepts](core_concepts.md), [Controllers & Templates](controllers_and_templates.md), and [Layouts](layouts.md).

## Generated Specs

Generated apps include specs for the default model, controller, template, and component. Run them from the generated app with:

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
RSpec.describe MyApp::HomeController do
  let(:application) { MyApp::Application.new }

  it "renders the home screen" do
    response = described_class.new(application: application).dispatch(:show)

    expect(response.body).to include("Home")
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

## Template Specs

Resolve and render templates directly when testing template output:

```ruby
template = Charming::Templates.resolve("home/show", root: app_root)
view = Charming::TemplateView.new(
  template: template,
  home: double(title: "Home"),
  theme: Charming::UI::Theme.default
)

expect(view.render).to include("Home")
```

Templates can use normal view helpers. Strip ANSI codes when assertions do not need styling:

```ruby
body = Charming::UI::Width.strip_ansi(view.render)
expect(body).to include("Home")
```

Controller tests can cover template rendering through `render :show`:

```ruby
response = MyApp::HomeController.new(application: application).dispatch(:show)

expect(response.body).to include("Home")
```

## Class-Based View Specs

Class-based views are plain objects. Pass assigns to `new` and call `render`:

```ruby
view = MyApp::HomeView.new(
  home: double(title: "Home"),
  theme: Charming::UI::Theme.default
)

expect(view.render).to include("Home")
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
  ],
  width: 80,
  height: 24
)

Charming::Runtime.new(MyApp::Application.new, backend: backend).run

expect(backend.frames).to eq(["Count: 0", "Count: 1"])
```

`MemoryBackend` accepts `events:`, `width:`, and `height:` keyword args. After running, inspect `backend.frames` to assert against rendered terminal frames.

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

## Renderer Specs

For renderer-level tests, pass a custom `renderer:` to `Charming::Runtime.new` or test renderer classes directly with `MemoryBackend`.

Backend and renderer classes under `Charming::Internal` are mostly test-facing implementation details. Prefer `MemoryBackend` for app and framework specs unless you specifically need TTY integration behavior.

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
