# Charming

A Rails-inspired terminal user interface framework for **Ruby 4+**.

Charming gives terminal apps familiar application structure: routes, controllers, state objects, templates, layouts, reusable components, themes, keyboard bindings, command palettes, timers, background tasks, and testable terminal backends.

## Project Status

Charming is still in its infancy and is under constant development. APIs, behavior, and generated app structure may change until the project reaches a stable `1.0` release.

## Quick Start

Install the Charming CLI gem on your machine:

```bash
gem install charming
```

Generate and run an app:

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
| [Docs Index](docs/README.md) | Suggested reading paths and all documentation links. |
| [Getting Started](docs/getting_started.md) | Build and run a generated Charming app. |
| [Core Concepts](docs/core_concepts.md) | App architecture, runtime flow, ephemeral controllers, and state. |
| [Routing](docs/routing.md) | `root`, `screen`, dynamic params, route titles, and route order. |
| [Controllers & Templates](docs/controllers_and_templates.md) | Actions, `render :show`, `render_template`, key bindings, commands, timers, and tasks. |
| [Layouts](docs/layouts.md) | Template layouts, `yield_content`, split panes, overlays, responsive layouts, and styles. |
| [State](docs/state.md) | `ApplicationState`, typed attributes, validations, and session-backed state. |
| [Database](docs/database.md) | Optional SQLite persistence with Active Record models and migrations. |
| [Components](docs/components.md) | Built-in components, custom components, and interaction return values. |
| [Themes](docs/themes.md) | Theme registration, tokens, and runtime theme switching. |
| [API Reference](docs/api.md) | Compact public API reference. |
| [Testing](docs/testing.md) | Controller, template, component, runtime, timer, and task tests. |

## Generated App Structure

The generator produces a Bundler gem with a Rails-like structure:

```text
app/controllers/                         # controller actions and input bindings
app/state/                               # session-backed TUI state
app/models/                              # optional Active Record models
app/views/home/show_view.rb              # screen view classes
app/views/layouts/application_layout.rb  # layout view class
app/components/                          # reusable components
config/routes.rb                         # route definitions
lib/my_app.rb                            # namespace loader (Zeitwerk)
exe/my_app                               # executable entry point
```

Generated apps include a sidebar/content layout, command palette, focus management, theme switching, and default key bindings for commands (`p`) and quit (`q`).

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
