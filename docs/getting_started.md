# Getting Started

Charming is a Rails-inspired terminal UI framework for Ruby 4+. A generated Charming app is a small Ruby gem with routes, controllers, models, ERB templates, layouts, components, and an internal terminal runtime.

## Install Charming

Install the CLI gem on your machine:

```sh
gem install charming
```

Then generate an app:

```sh
charming new my_app
cd my_app
bundle install
bundle exec exe/my_app
```

## Generated Files

Generated apps use Rails-like folders:

```text
app/components/
app/controllers/
app/models/
app/views/home/show.tui.erb
app/views/layouts/application.tui.erb
config/routes.rb
exe/my_app
lib/my_app.rb
lib/my_app/application.rb
spec/
```

The executable boots the app with:

```ruby
Charming.run(MyApp::Application.new)
```

`Charming.run` starts the runtime with the default TTY backend. Tests and custom integrations can instantiate `Charming::Runtime` directly to pass `backend:`, `renderer:`, `clock:`, or `task_executor:`.

## Core Concepts

The generated app flow is:

```text
Route -> Controller Action -> Template -> Layout -> Renderer -> Terminal
```

Controllers are created fresh for each dispatch. Do not keep persistent state on controller instance variables. Put durable state in application models and retrieve it with `model(:name, ModelClass)`.

## Routes

Routes live in `config/routes.rb`:

```ruby
MyApp::Application.routes do
  root "home#show"
  screen "/cities/:id", to: "cities#show", title: "City"
end
```

`root` maps `/` to a controller action. `screen` maps a path to `controller#action`. The optional `title:` is used by generated sidebar layouts.

Dynamic segments are available as symbol-keyed controller params:

```ruby
module MyApp
  class CitiesController < ApplicationController
    def show
      render "City #{params[:id]}"
    end
  end
end
```

Dynamic params match one path segment. Exact routes win over dynamic routes, so `/cities/new` can be defined separately from `/cities/:id`.

## Controllers

Controllers handle app events and render responses:

```ruby
module MyApp
  class HomeController < ApplicationController
    key "up", :increment
    key "down", :decrement
    key "p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global

    command "Refresh", :refresh
    command "Quit app", :quit

    def show
      render :show, home: home, palette: command_palette
    end

    def increment
      home.count += 1
      show
    end

    def decrement
      home.count -= 1
      show
    end

    private

    def home
      model(:home, HomeModel)
    end
  end
end
```

Useful controller APIs:

- `key "q", :quit` dispatches a content key to an action.
- `key "q", :quit, scope: :global` works from any focused pane.
- `command "Label", :action` adds a command palette item.
- `render :show, **assigns` renders the current controller's `show` template.
- `render_template "custom/page", **assigns` renders an explicit template path.
- `render "literal text"` renders a literal string.
- `navigate_to "/path"` changes routes.
- `quit` exits the runtime.
- `params` exposes route params.
- `screen.width` and `screen.height` expose terminal dimensions.
- `model(:name, ModelClass)` stores and reuses app state in the application session.
- `theme` exposes the current app theme.
- `command_palette` returns the active command palette component when open.

## Models

Models inherit from `Charming::ApplicationModel`, which uses ActiveModel attributes and validations.

```ruby
module MyApp
  class HomeModel < ApplicationModel
    attribute :title, :string, default: "Home"
    attribute :count, :integer, default: 0
    attribute :status, :string, default: "Ready"
  end
end
```

Use models for state that must survive key presses, timers, task completions, and route renders.

Common attribute types include `:string`, `:integer`, `:float`, `:boolean`, `:date`, `:datetime`, and `:time`.

## Templates

Generated screen views are ERB templates under `app/views`.

`render :show` in `HomeController` resolves this file:

```text
app/views/home/show.tui.erb
```

Example template:

```erb
<%= text home.title, style: theme.title %>
<%= text "Status: #{home.status}", style: theme.muted %>
<%= text "Press p for commands, q to quit.", style: theme.muted %>
```

Templates get assigns from the controller. In this example, `home` came from:

```ruby
render :show, home: home, palette: command_palette
```

Templates also get common helpers:

| Helper | Purpose |
|--------|---------|
| `text(value, style: nil)` | Render styled text. |
| `box(value, style: nil)` | Style or border a block. |
| `box(style: style) { ... }` | Capture nested helper output into a styled block. |
| `row(*items, gap: 0)` | Join blocks side by side. |
| `column(*items, gap: 0)` | Stack blocks vertically. |
| `render_component(component)` | Render a component or partial object. |
| `render_partial(partial)` | Alias for `render_component`. |
| `yield_content` | Render the wrapped screen inside a layout. |
| `focused?(slot)` | Ask the controller whether a focus slot is active. |

Template extensions:

| Extension | Purpose |
|-----------|---------|
| `.tui.erb` | Primary terminal template format. |
| `.txt.erb` | Plain text template format. |

If both exist for the same template name, `.tui.erb` is preferred.

## Layouts

Generated apps use a controller layout:

```ruby
module MyApp
  class ApplicationController < Charming::Controller
    layout "layouts/application"
    focus_ring :sidebar, :content
  end
end
```

This resolves:

```text
app/views/layouts/application.tui.erb
```

Layouts are templates. Use `yield_content` to place the current screen inside the wrapper.

```erb
<%
sidebar = box("Home\nSettings", style: theme.border.border(:rounded).padding(1, 2).width(20))
main = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
frame = row(sidebar, main, gap: 1)
%><%= Charming::UI.place(frame, width: screen.width, height: screen.height) %>
```

Layouts receive these standard assigns:

| Assign | Purpose |
|--------|---------|
| `content` | The already-rendered screen body. |
| `screen` | Current terminal dimensions. |
| `controller` | Current controller instance. |
| `theme` | Active theme. |

Any assigns passed to the screen template are also available to the layout.

## Layout Patterns

Charming has two layers of layout tools:

| Layer | Use For | APIs |
|-------|---------|------|
| View composition | Building blocks relative to each other | `row`, `column`, `box`, `text` |
| Spatial placement | Placing blocks on fixed terminal canvases | `Charming::UI.center`, `place`, `overlay` |

### Stacked Layouts

Use `column` for vertical screens, forms, and status panels:

```erb
<%= column(
  text("Create Project", style: theme.title),
  row(text("Name", style: theme.muted.width(12)), text(project.name, style: theme.text)),
  row(text("Owner", style: theme.muted.width(12)), text(project.owner, style: theme.text)),
  text("Tab moves focus. Enter saves.", style: theme.muted),
  gap: 1
) %>
```

### Sidebars And Split Panes

Use `row` to place panels side by side. Give panels explicit widths so multiline content aligns correctly:

```erb
<%
sidebar = box(nav_items, style: theme.border.border(:rounded).padding(1, 2).width(22))
details = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
%><%= row(sidebar, details, gap: 1) %>
```

### Responsive Layouts

Layouts can branch on `screen.width` and `screen.height`:

```erb
<%
narrow = screen.width < 72 && screen.height >= 20
body = narrow ? column(sidebar, main_content, gap: 1) : row(sidebar, main_content, gap: 1)
%><%= Charming::UI.place(body, width: screen.width, height: screen.height) %>
```

### Centered Dialogs

Use `Charming::UI.center` to put a block in the middle of a fixed-size canvas:

```erb
<%
dialog = box(
  column(
    text("Delete project?", style: theme.title),
    text("This cannot be undone.", style: theme.warn),
    text("Enter confirms. Escape cancels.", style: theme.muted),
    gap: 1
  ),
  style: theme.border.border(:rounded).padding(1, 2).width(42)
)
%><%= Charming::UI.center(dialog, width: screen.width, height: screen.height) %>
```

### Modal Overlays

Use `Charming::UI.overlay` to draw a modal, palette, tooltip, or toast over an existing frame:

```erb
<%
body = Charming::UI.place(frame, width: screen.width, height: screen.height)

if palette
  modal = render_component Charming::Components::Modal.new(
    title: "Command palette",
    content: palette,
    help: "Type to filter. Enter selects. Escape closes.",
    width: 52,
    theme: theme
  )
  body = Charming::UI.overlay(body, modal)
end
%><%= body %>
```

### Style Chaining

`Charming::UI::Style` objects are immutable and chainable:

```erb
<%
panel_style = Charming::UI.style
  .foreground(:bright_cyan)
  .background("#101820")
  .bold
  .border(:rounded, foreground: :bright_magenta)
  .padding(1, 2)
  .width(40)
  .align(:center)
%><%= box("System ready", style: panel_style) %>
```

## Components

Components inherit from `Charming::Component`, which itself inherits from `Charming::View`. Components can render text and can optionally handle input.

```ruby
class CounterComponent < Charming::Component
  def render
    text "Count: #{count}", style: theme.info
  end
end
```

Render one from a template:

```erb
<%= render_component CounterComponent.new(count: home.count, theme: theme) %>
```

Interactive components should expose `handle_key(event)` and may expose `handle_mouse(event)`. Components return `:handled`, `[:selected, value]`, `:cancelled`, or `nil` to communicate event handling results.

## Command Palette

Generated apps bind `p` to `open_command_palette` and add commands in `ApplicationController`:

```ruby
command "Home" do
  navigate_to "/"
end

command "Theme", :open_theme_palette
command "Quit app", :quit
```

When the palette is open, it receives key events before normal controller key bindings.

## Timers And Tasks

Timers dispatch periodically while a route is active:

```ruby
timer :clock, every: 0.5, action: :tick

def tick
  home.count += 1
  show
end
```

Tasks run work through the app task executor and dispatch a `TaskEvent` when complete:

```ruby
on_task :refresh_home, action: :refresh_loaded

def refresh
  run_task(:refresh_home) { "Loaded" }
  show
end

def refresh_loaded
  home.status = event.error? ? event.error.message : event.value
  show
end
```

## Themes

Applications can register built-in themes:

```ruby
class MyApp::Application < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor
end
```

Views, templates, and components should prefer semantic theme styles:

```ruby
text "Title", style: theme.title
text "Help", style: theme.muted
```

Default tokens:

| Token | Meaning |
|-------|---------|
| `text` | Primary text |
| `title` | Bright title text |
| `muted` | Secondary text |
| `border` | Border styling |
| `selected` | Selected/focused item styling |
| `info` | Informational accent |
| `warn` | Warning accent |

## Generate More Files

Inside an app:

```sh
charming generate screen forecast
charming generate controller forecast show
charming generate view forecast show
charming generate component forecast_card
```

`generate` can be shortened to `g`.

## Run Tests

Generated apps include RSpec specs. Run them with:

```sh
bundle exec rspec
```

For framework development, use:

```sh
bin/check
```

For controller, template, component, timer, task, and runtime testing patterns, see [Testing](testing.md).
