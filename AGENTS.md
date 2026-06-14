# CHARMING — Agent Guide

## Project

**Charming** is a Rails-inspired terminal user interface (TUI) framework for **Ruby 4+**. It is a **bundler gem** (`charming.gemspec`) providing applications, routing, controller actions, application state, views, components, rendering, generators, and a command palette — with an internal terminal backend layered behind `MemoryBackend` and `TTYBackend`.

---

## Commands

```bash
bundle install          # after checkout or gemspec changes
bin/check               # run everything: RSpec + Standard Ruby
bin/rspec               # tests only
bin/lint                # style checks only
bin/format              # auto-format with Standard Ruby
```

Demo app:
```bash
cd examples/demo_app && bundle install && bundle exec exe/demo_app
```

---

## File Layout

```
lib/charming/             # framework source
  application.rb          # Rails-style Application class (routes, session)
  application_state.rb    # ActiveModel::Model + Attributes
  controller.rb           # dispatch, key/timer bindings, state(session), render/quit/navigate
  router.rb               # route drawing
  runtime.rb              # main event loop (TTY or MemoryBackend)
  screen.rb               # terminal dimensions (width, height)
  response.rb             # RenderResponse / NavigateResponse / QuitResponse
  events.rb               # KeyEvent, ResizeEvent, TimerEvent (Data classes)
  view.rb                 # render helpers: text, box, row, column, style, render_component
  component.rb            # ← inherits View (assigns, helpers)
  ui/                     # Lip Gloss-like styling/layout (ANSI, borders, padding, alignment, dimensions)
  components/             # reusable TUI widgets
    text_input.rb
    list.rb
    command_palette.rb
    modal.rb
    viewport.rb           # scrollable content area
    spinner.rb
  generators/             # `charming new` / `charming generate` scaffold code
  internal/
    terminal/
      tty_backend.rb      # real TTY I/O (tty-cursor, tty-reader, tty-screen)
      memory_backend.rb   # in-memory I/O for specs & scripts
  renderer/
    full_repaint.rb

spec/                     # RSpec tests (117+ examples)
  examples/               # generated-style demo app tests
  components/             # component specs
  ui/                     # UI subsystem specs
  internal/               # backend/renderer specs
examples/demo_app/        # canonical demo (generated-style, customized)
```

---

## Key Architecture

```
Application → Router → Controller → ApplicationState → View → Component → UI
                              Runtime → Renderer → TTY/Memory Backend
```

- **Runtime** is the main loop: reads events from the backend, dispatches to controller (action keys, timer keys) or components, renders the response.
- A fresh controller instance is created **per dispatch**. Never store state on the controller.
- **Application state** is the only place for persistent TUI state; state objects are stored in `session` via `Controller#state(name, klass, **attrs)`.
- **Components** inherit from `View` to reuse assign readers and helpers (`text`, `box`, `row`, `column`, `render_component`).

---

## Key APIs

### Application

```ruby
class MyApp < Charming::Application
  routes do
    root "home#index"
  end
end
```

### Controller

```ruby
class HomeController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "q", :quit

  command "Quit", :quit

  timer :blink, every: 0.5, action: :toggle_spinner

  def show
    render counter.name
  end

  def index
    render_index
  end

  def increment
    counter.value += 1
    show
  end

  private
  def counter
    @counter ||= state(:counter, CounterState)
  end
end
```

### ApplicationState

```ruby
class CounterState < Charming::ApplicationState
  attribute :value, :integer, default: 0
end
```

### Components

Components expose `handle_key(event)` for interactive widgets. Return conventions:

| Return value       | Meaning              |
|--------------------|-----------------------|
| `:handled`        | Key consumed          |
| `[:selected, obj]`| Item selected         |
| `:cancelled`       | Cancelled (e.g. ESC) |
| `nil`              | Not handled           |

Components currently inherit from `View` and use `render` to produce the displayed string.

### Audio playback

`Charming::Audio::Player` plays a sound file by shelling out to a system audio binary
(no new gem dependency). Backends are resolved in priority order: `ffplay` (from ffmpeg)
on any platform, then OS-native players — `afplay` on macOS; `paplay`, `mpg123`, `aplay`
on Linux — raising `Charming::Audio::Player::Unavailable` when none are installed. The
player is **not** a view object: it holds a live child process, so keep it in `session`
(e.g. `session[:audio] ||= Charming::Audio::Player.new`) rather than rebuilding it per
render. For non-blocking playback plus clean teardown on quit, drive it from a `run_task`:

```ruby
run_task(:audio) do
  player.play(sound_path)
  player.wait
ensure
  player.stop   # no-op on normal finish; reaps the child if shutdown interrupts the task
end
```

`Charming::Components::Audio` is the optional one-line status view (`▶`/`■` + label) that
reads `player.playing?`. The `System` adapter (`Charming::Audio::System`) is injectable so
specs never shell out.

---

## Code Style (Standard Ruby)

- **Ruby 4.0+** target
- `frozen_string_literal: true` on every file
- Use `bin/format` for auto-formatting
- Use `bin/lint` for style checks
- Follow Standard Ruby formatting rather than invoking RuboCop directly

---

## Testing

RSpec specs live in `spec/`. The `MemoryBackend` is used almost exclusively in specs so no real TTY is needed.

```bash
bundle exec rspec spec/path/to/file_spec.rb   # single file
bundle exec rspec                               # all specs
```

When adding specs for a backend-dependent feature, prefer `MemoryBackend` for unit specs and reserve `TTYBackend` for integration-level tests.

---

## Key Gotchas

1. **Controllers are ephemeral** — the Runtime creates new instances per event. Application state must live in `ApplicationState` objects stored in `session` via `Controller#state(...)`.
2. **Components inherit View** — they get `assigns`, helper methods, and `render`. They do NOT have their own lifecycle separate from `View`.
3. **`Charming.run(app)` is the entry point** — it instantiates `Runtime` with an optional backend. Tests pass `backend: MemoryBackend.new(...)` directly.
4. **Command palette keys take priority** — an open palette intercepts key events before controller `key_bindings`.
5. **Timers emit `TimerEvent`s** — controllers declare them with `timer :name, every: n, action: :method`; the runtime dispatches through `Controller#dispatch_timer`.
6. **`View#render` returns a string** — the controller wraps it in a `Response.render(...)` which `Runtime` sends to the renderer.
7. **`Screen` dimensions** flow: backend → runtime → controller (as `screen` arg) → view helpers. Use `@screen.width` and `@screen.height` in controllers for layout.
8. **The `render` view helper produces an `UI::Style`-styled string**, and controller `render(...)` wraps that in a response. Don't confuse them.
