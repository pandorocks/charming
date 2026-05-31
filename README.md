# Charming

A Rails-inspired terminal user interface framework for **Ruby 4+**.

```ruby
class MyApp < Charming::Application
  routes do
    root "counter#show"
  end
end

class CounterController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "q", :quit, scope: :global

  def show
    render "Count: #{counter.count}"
  end

  def increment
    counter.count += 1
    show
  end

  def decrement
    counter.count -= 1
    show
  end

  private

  def counter
    model(:counter, CounterModel)
  end
end

class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "charming"
```

Then execute:

```bash
bundle install
```

## Generating an App

Create a complete, runnable Charming app with the built-in generator:

```bash
charming new my_app
cd my_app
bundle exec exe/my_app
```

The generator produces a full Bundler gem with conventional Rails-like structure:

```text
app/controllers/          # application controllers
app/models/               # persistent state models
app/views/                # screen views
app/components/           # reusable widgets (AppFrame, etc.)
config/routes.rb          # route definitions
lib/my_app.rb             # namespace loader (Zeitwerk)
exe/my_app                # executable entry point
```

Inside a generated app, scaffold more code:

```bash
charming generate controller users index show
charming generate view details
charming generate component status_badge
charming g controller products        # shortcut
```

Generated apps ship with a command palette (press `p`) and a sidebar navigation layout with theming and focus management baked in.

## Running Without the Generator

You can also build an app from scratch. Run it with:

```ruby
Charming.run(MyApp.new)
#        ^ entry point — starts the terminal event loop
```

The `Charming::Runtime` manages the terminal lifecycle, reads events from a TTY backend, and dispatches them to controllers. An in-memory backend (`MemoryBackend`) is available for scripting and testing without a real terminal.

## Application & Routing

Define routes with `root` and `screen` — each maps a URL path to a controller and action:

```ruby
class MyApp < Charming::Application
  routes do
    root "home#index"
    screen "/cities/:id", to: "cities#show"
  end
end
```

Dynamic segments (`:id`) are available in controllers through `params`:

```ruby
class CitiesController < Charming::Controller
  def show
    render "City #{params[:id]}"
  end
end
```

Exact routes take precedence over dynamic routes. Multiple screens are listed in route order and rendered as sidebar entries (handled automatically by generated app layouts).

## Controllers

The base `Charming::Controller` provides key bindings, command palette entries, timer-driven actions, navigation, and state management:

**Key bindings** — strings or symbols mapped to action methods, scoped as either content-focused or global:

```ruby
class HomeController < Charming::Controller
  key "up", :increment
  key "j", :navigate_down, scope: :content
  key "q", :quit, scope: :global
end
```

**Command palette** — entries visible in the fuzzy-search command palette. Accepts a method name or an inline block:

```ruby
command "Save changes", :save
command "Clear" do
  @model = reset_model
end
```

**Timers** — periodic actions that fire at a given interval on the current controller:

```ruby
timer :blink, every: 0.5, action: :toggle_spinner
```

**Model storage** — models are stored in session and lazily instantiated:

```ruby
def counter
  model(:counter, CounterModel)
end
#        ^ name    ^ class
```

Subsequent calls with the same name return the cached instance. Use this pattern to define accessors on your controllers.

**Navigation** — redirect to a new route or quit the application:

```ruby
navigate_to "/settings"         # redirect
quit                             # exit the app
open_command_palette             # open command palette
close_command_palette            # close it
use_theme :phosphor              # switch theme (persists in session)
```

## Models

Application models inherit from `Charming::ApplicationModel`, which includes `ActiveModel::Model` and `ActiveModel::Attributes`:

```ruby
class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0

  validate :count_gte_zero do
    errors.add(:count, "must be >= 0") if count < 0
  end
end
```

Models are the only place persistent state should live. Controllers are created fresh per event — never store state on them.

## Views

Views inherit from `Charming::View` and expose assigns (from `initialize`) as instance-local accessor methods:

```ruby
class HomeView < Charming::View
  def render
    row(title, subtitle, gap: 2)
  end

  private

  def title
    text "Hello!", style: theme.title
  end

  def subtitle
    text "World", style: theme.muted
  end
end
```

Views use `row`, `column` for layout, `box` for bordered containers, and `text` for styled output. Assigns passed to `initialize` become reader methods automatically:

```ruby
class HomeView < Charming::View
  # Pass assigns via initialize; they are accessible as regular methods inside render()
end

view = HomeView.new(title: "Hello", count: 42)
# view.title → "Hello"
# view.count → 42
```

Defining your own method with the same name will override the auto-generated accessor.

### Layouts

Layouts are views that wrap the current screen with a wrapper (sidebar, header, etc.):

```ruby
class ApplicationController < Charming::Controller
  layout Layouts::Application
end
```

Subclasses inherit their parent's layout. Override with `layout false` to disable wrapping.

Layouts use `yield_content` to render the primary screen and receive `screen`, `controller`, and `theme` as assigns:

```ruby
module MyProject
  module Layouts
    class Application < Charming::View
      def render
        body = Charming::UI.place(content, width: screen.width, height: screen.height)
        return body unless command_palette_open?

        Charming::UI.overlay(body, command_palette.render)
      end
    end
  end
end
```

### Partials

Render class-based partial views from other views:

```ruby
render_component HeaderView.new(title: "Dashboard")
#        ^ component is a View subclass or Component
```

Components are just `Charming::View` subclasses — they gain the same assigns, helpers, and rendering behavior.

## Themes

Applications register named themes from bundled JSON files or custom locations:

```ruby
class MyApp < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor

  theme :custom, from: "config/themes/custom.json"
end
```

Charming ships with the Phosphor theme by default. Views use semantic tokens — not hardcoded colors — for all styling:

```ruby
text "Welcome", style: theme.title      # bright cyan + bold
text "Status",  style: theme.muted     # dim gray
text "Alert",   style: theme.info      # cyan
```

## Components

Charming ships with interactive terminal widgets that inherit from `Charming::View` (and thus gain all View helpers):

| Component | Description |
|-----------|-------------|
| `TextInput` | Editable text field with cursor movement, selection, and character insertion |
| `List` | Selectable list with keyboard navigation (up/down/home/end/enter) and mouse support |
| `Modal` | Overlay dialog with title, content, and help text |
| `CommandPalette` | Fuzzy-search command input used internally by the framework |
| `Viewport` | Scrollable container for tall content lists |
| `Spinner` | Animated progress indicator |
| `ActivityIndicator` | Spinner variant (same underlying widget) |
| `Progressbar` | A text-based progress bar |
| `Table` | Unicode-rendered data table with keyboard navigation and mouse selection |
| `KeyboardHandler` | Key-mapping mixin for custom components |

All components accept a `theme:` parameter and are rendered from views via `render_component`:

```ruby
render_component List.new(
  items: ["Alpha", "Beta", "Gamma"],
  selected_index: 0,
  theme: theme
)
```

Components return specific values from their `handle_key(event)` methods — the framework recognizes conventions like `[:selected, item]` and `:cancelled`. They also provide a `handle_mouse(event)` method for mouse-driven interaction.

## Async Tasks

Dispatch background work via `run_task` on controllers. Results arrive as `TaskEvent`s that trigger controller actions:

```ruby
class HomeController < Charming::Controller
  on_task :fetch_data, action: :data_loaded

  def load_data
    run_task :fetch_data do
      # runs in a background thread
      sleep 2
      "done"
    end
  end

  def data_loaded
    render "Task complete!"
  end
end
```

Register handlers with `on_task` on the controller and dispatch work with `run_task`.

## Focus Management

Multi-screen layouts can define focusable areas using `focus_ring`:

```ruby
class ApplicationController < Charming::Controller
  focus_ring :sidebar, :content
end
```

This enables keyboard-driven focus traversal — `Tab` cycles forward, `Shift+Tab` backward. Use `focused?(slot)`, `focus_sidebar`, and `focus_content` to programmatically control focus:

```ruby
def show
  focus_sidebar if params[:sidebar]
  render HomeView.new(...)
end
```

## Layout Primitives

The `Charming::UI` module provides layout primitives for building custom screen layouts. These work independently of the runtime and backends:

| Method | Description |
|--------|-------------|
| `Style.new` | Create a new style for chaining colors, padding, borders, alignment |
| `UI.join_horizontal(*blocks, gap: 0)` | Place blocks side-by-side |
| `UI.join_vertical(*blocks, gap: 0)` | Stack blocks vertically |
| `UI.center(block, width:, height:)` | Center a block in a fixed canvas |
| `UI.place(block, width:, height:, top:, left:, background:)` | Place anywhere on a canvas |
| `UI.overlay(base, overlay, top:, left:)` | Overlay content atop another |

All methods work with ANSI-styled strings and correctly handle Unicode display widths:

```ruby
body = UI.join_horizontal(sidebar, main_content, gap: 1)
canvas = UI.place(body, width: screen.width, height: screen.height)
Charming::UI.overlay(canvas, modal_view.render)
```

## Testing

Charming uses an in-memory backend (`MemoryBackend`) for testing, so specs run without a real terminal. Pass `backend: MemoryBackend.new(...)` to `Charming::Runtime`:

```ruby
backend = Charming::Internal::Terminal::MemoryBackend.new(
  events: [
    Charming::KeyEvent.new(key: :up),
    Charming::KeyEvent.new(key: :q)
  ]
)
runtime = described_class.new(app, backend: backend)
runtime.run

expect(backend.frames).to eq(["Count: 0", "Count: 1"])
#                            ^ captured terminal output, one frame per render
```

The `MemoryBackend` constructor accepts `events:` (a series of events to feed the loop), and `width:` / `height:` for screen dimensions. After running, assertions go against `backend.frames` — an array capturing each rendered terminal frame passed through `write_frame`. This pattern is used throughout the test suite.

## Development

After checking out the repo, run:

```bash
bundle install
bin/check            # run everything — RSpec + Standard Ruby
```

Common binstubs:

```bash
bin/rspec             # run specs only
bin/format            # auto-format with Standard Ruby
bin/lint              # style checks with Standard Ruby
bin/check             # run everything
```
