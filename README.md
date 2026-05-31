# Charming

A Rails-inspired terminal user interface framework for **Ruby 4+**.

Charming gives terminal apps familiar application structure: routes, controllers, models, templates, layouts, reusable components, themes, keyboard bindings, command palettes, timers, background tasks, and testable terminal backends.

## Installation

Install the Charming CLI gem on your machine:

```bash
gem install charming
```

Then generate a new app:

```bash
charming new my_app
cd my_app
bundle install
bundle exec exe/my_app
```

Charming can also be added to an existing Ruby project with Bundler, but the primary workflow is installing the gem globally and using `charming new` to create a complete app.

## Documentation

| Guide | Purpose |
|-------|---------|
| [Getting Started](docs/getting_started.md) | Build and understand a generated Charming app. |
| [API Reference](docs/api.md) | Compact reference for public framework APIs. |
| [Testing](docs/testing.md) | Test controllers, templates, components, timers, tasks, and runtime behavior. |

## Generated App Structure

The generator produces a Bundler gem with a Rails-like structure:

```text
app/controllers/                         # controller actions and input bindings
app/models/                              # persistent state models
app/views/home/show.tui.erb              # screen templates
app/views/layouts/application.tui.erb    # layout template
app/components/                          # reusable components
config/routes.rb                         # route definitions
lib/my_app.rb                            # namespace loader (Zeitwerk)
exe/my_app                               # executable entry point
```

Generated apps include:

- A base `ApplicationController`
- A sidebar + content layout
- A command palette bound to `p`
- A quit binding bound to `q`
- Focus management for sidebar/content traversal
- A theme command for switching themes at runtime

Generate more files inside an app:

```bash
charming generate screen forecast
charming generate controller users index show
charming generate view users index
charming generate component status_badge
charming g controller products        # shortcut
```

## Core Concepts

Charming apps follow this shape:

```text
Application -> Router -> Controller -> Template/Layout -> Component -> UI
                         Runtime -> Renderer -> Terminal Backend
```

The important rule is that **controllers are ephemeral**. Charming creates a fresh controller instance for each dispatch. Store persistent state in `ApplicationModel` objects through `Controller#model`, not in controller instance variables.

## Routing

Generated apps define routes in `config/routes.rb` by calling `routes` on the application class:

```ruby
MyApp::Application.routes do
  root "home#show"
  screen "/cities", to: "cities#index", title: "Cities"
  screen "/cities/:id", to: "cities#show"
end
```

`root` maps `/` to a controller action. `screen` maps a path to `controller#action`. Dynamic segments are available through `params`:

```ruby
class MyApp::CitiesController < MyApp::ApplicationController
  def show
    render "City #{params[:id]}"
  end
end
```

## Controllers And Templates

Controllers dispatch actions, bind input, navigate between routes, run tasks, and render responses.

Generated controllers render templates by symbol:

```ruby
module MyApp
  class HomeController < ApplicationController
    key "p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global

    def show
      render :show, home: home, palette: command_palette
    end

    private

    def home
      model(:home, HomeModel)
    end
  end
end
```

`render :show` resolves `app/views/home/show.tui.erb`. Use `render_template "custom/page", **assigns` for explicit template paths.

Templates are ERB files with access to view helpers and assigns:

```erb
<%= text home.title, style: theme.title %>
<%= text "Press p for commands, q to quit.", style: theme.muted %>
```

Class-based views are still supported. Passing a `Charming::View` or component object to `render` renders that object directly.

## Layouts

Generated apps use a template layout:

```ruby
class ApplicationController < Charming::Controller
  layout "layouts/application"
end
```

Layouts receive the same helper context as templates, plus standard assigns:

| Assign | Purpose |
|--------|---------|
| `content` | The already-rendered screen body. |
| `screen` | Current terminal dimensions. |
| `controller` | Current controller instance. |
| `theme` | Active theme. |

Use `yield_content` to place the screen body:

```erb
<%
sidebar = box("Home\nSettings", style: theme.border.border(:rounded).padding(1, 2).width(20))
main = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
frame = row(sidebar, main, gap: 1)
%><%= Charming::UI.place(frame, width: screen.width, height: screen.height) %>
```

Layout primitives include `text`, `box`, `row`, `column`, `Charming::UI.place`, `Charming::UI.center`, `Charming::UI.overlay`, and immutable style chaining through `Charming::UI.style` or theme tokens.

For deeper layout examples, including split panes, responsive layouts, overlays, and dashboard grids, see [Getting Started](docs/getting_started.md#layout-patterns).

## Models

Application models inherit from `Charming::ApplicationModel`, which includes `ActiveModel::Model` and `ActiveModel::Attributes`:

```ruby
class MyApp::HomeModel < MyApp::ApplicationModel
  attribute :title, :string, default: "Home"
  attribute :count, :integer, default: 0
end
```

Use models for state that must survive key presses, timer ticks, task completions, and route renders.

## Components

Charming ships with reusable terminal widgets that inherit from `Charming::View`:

| Component | Description |
|-----------|-------------|
| `TextInput` | Editable text field with cursor movement, selection, and insertion. |
| `List` | Selectable list with keyboard navigation and mouse support. |
| `Modal` | Overlay dialog with title, content, and help text. |
| `CommandPalette` | Fuzzy-search command input used internally by the framework. |
| `Viewport` | Scrollable container for tall content lists. |
| `Spinner` | Animated progress indicator. |
| `ActivityIndicator` | Spinner-style activity indicator. |
| `Progressbar` | Text-based progress bar. |
| `Table` | Unicode-rendered data table with keyboard and mouse selection. |
| `KeyboardHandler` | Key-mapping mixin for custom components. |

Render components from templates or views with `render_component`:

```erb
<%= render_component Charming::Components::List.new(
  items: ["Alpha", "Beta", "Gamma"],
  selected_index: 0,
  theme: theme
) %>
```

## Themes

Applications register named themes from bundled JSON files or custom locations:

```ruby
class MyApp::Application < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor
end
```

Views and templates should use semantic tokens instead of hardcoded colors:

```ruby
text "Welcome", style: theme.title
text "Status", style: theme.muted
text "Alert", style: theme.info
```

Default tokens include `text`, `title`, `muted`, `border`, `selected`, `info`, and `warn`. Themes can be switched at runtime with `use_theme(:name)` or the generated `open_theme_palette` command.

## Runtime And Testing

Most apps start through `Charming.run(app)`, which builds a `Charming::Runtime` and runs the terminal event loop.

For tests, use `Charming::Internal::Terminal::MemoryBackend` to script terminal events without a real terminal. See [Testing](docs/testing.md) for controller, template, component, timer, task, and runtime examples.

## Development

After checking out the repo, run:

```bash
bundle install
bin/check
```

Common binstubs:

```bash
bin/rspec             # run specs only
bin/format            # auto-format with Standard Ruby
bin/lint              # style checks with Standard Ruby
bin/check             # run everything
```
