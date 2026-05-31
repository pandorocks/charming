# Roadmap

## Product Direction

Charming is a Rails-inspired terminal user interface framework for Ruby.

The public API should feel familiar to Rails developers: applications, routes, controllers, views, components, rendering, and conventions. Internally, Charming keeps terminal I/O behind a backend seam so the runtime, tests, components, and application code do not depend directly on TTY gems.

## Architectural Principles

- Prefer Rails-like public concepts over Elm-style public concepts.
- Keep terminal input/output behind internal backend interfaces.
- Keep the in-memory backend as a first-class test backend.
- Keep styling and layout usable independently of the runtime.
- Keep dependencies explicit and ergonomic.
- Make examples and tests part of the deliverable, not afterthoughts.

## Completed

- Generated a conventional Bundler gem structure.
- Switched testing to RSpec.
- Added Standard Ruby formatting/linting and a default `rake` task.
- Set Ruby floor to `>= 4.0.0`.
- Added ActiveModel-backed application models:
  - `Charming::ApplicationModel`
  - typed attributes and validations via `activemodel`
  - session-backed controller model lookup
- Replaced broad `tty` dependency with explicit runtime dependencies:
  - `tty-reader`
  - `tty-cursor`
  - `tty-screen`
  - `unicode-display_width`
- Added Rails-like foundation:
  - `Charming::Application`
  - `Charming::Router`
  - `Charming::Controller`
  - `Charming::Response`
  - `Charming::Runtime`
- Added normalized event types:
  - `Charming::Events::KeyEvent`
  - `Charming::Events::ResizeEvent`
  - `Charming::Events::MouseEvent`
  - `Charming::Events::TimerEvent`
  - `Charming::Events::TaskEvent`
- Added internal terminal backends:
  - `Charming::Internal::Terminal::MemoryBackend`
  - `Charming::Internal::Terminal::TTYBackend`
- Added full repaint renderer:
  - `Charming::Internal::Renderer::FullRepaint`
- Added differential renderer:
  - `Charming::Internal::Renderer::Differential`
- Added examples:
  - `examples/counter.rb`
  - `examples/counter_memory.rb`
- Added `Charming::Presentation::UI` styling and layout foundation:
  - ANSI foreground/background colors
  - 16-color, 256-color, and truecolor support
  - text attributes
  - padding
  - borders
  - width and height
  - horizontal alignment
  - Unicode-aware display width
  - ANSI-aware width measurement
  - horizontal and vertical joins
  - centering and overlay helpers
- Added Rails-like view foundation:
  - `Charming::Presentation::View`
  - keyword assigns exposed as reader methods
  - view helpers for `style`, `text`, `box`, `row`, and `column`
  - controller rendering of view objects
- Added component foundation:
  - `Charming::Presentation::Component`
  - component rendering from views
- Added first stateful component foundation:
  - `Charming::Presentation::Components::TextInput`
  - mutable value and cursor state
  - key handling for insertion, cursor movement, backspace, and delete
- Added selectable list component foundation:
  - `Charming::Presentation::Components::List`
  - selection movement and enter activation
  - custom item labels
  - fixed-height viewport rendering
- Added modal and command palette foundations:
  - `Charming::Presentation::Components::Modal`
  - `Charming::Presentation::Components::CommandPalette`
  - command filtering and selection
  - command palette controller helpers
  - command palette included in generated apps by default
- Added viewport and screen-aware rendering foundations:
  - `Charming::Presentation::Components::Viewport`
  - `Charming::Screen`
  - backend screen dimensions passed through runtime to controllers and views
  - runtime re-rendering for `Charming::Events::ResizeEvent`
  - TTY resize signal integration through `SIGWINCH`
  - viewport key handling for scrolling
- Added larger-screen interaction and async foundations:
  - timer-driven spinner and activity indicator rendering
  - `Charming::Presentation::Components::Progressbar`
  - `Charming::Presentation::Components::Table`
  - `Charming::TaskExecutor`
  - mouse event parsing and dispatch
- Added layout, partial, and theme support:
  - controller layouts
  - class-based partial rendering
  - bundled Phosphor TUI theme
- Added namespaced route resolution for generated apps.
- Added dynamic route parameters:
  - routes such as `/users/:id`
  - symbol-keyed controller params
  - exact route precedence over dynamic routes
- Added Rails-like generators:
  - `charming new <name>`
  - `charming generate controller <name> [actions]`
  - `charming generate view <name>`
  - `charming generate component <name>`
- Generated apps now include:
  - namespaced application and home models
  - a centered home screen
  - a default command palette opened with `p`
- Added RSpec coverage for routing, controller dispatch, runtime behavior, backends, renderer, and UI styling/layout.

## Current Milestone

Build toward a stable documentation and generated-app baseline.

The larger-screen interaction primitives and dynamic route parameters are now in place. The next milestone is documenting the framework well enough for generated apps and hand-written apps to follow the same conventions.

## Next

- Add API documentation and a getting-started guide.
- Harden generated app conventions and app loading.
- Add missing common widgets: checkbox, tabs, and status bar.

## Later

- Harden runtime teardown for signals.
- Expand layout features:
  - wrapping
  - clipping
  - vertical alignment
  - min/max width and height
  - viewport-aware layout
- Harden app file conventions and generated app loading.
- Expand examples and documentation.

## Verification

Run the full project check with:

```sh
bin/check
```

Run the interactive counter with:

```sh
bundle exec ruby examples/counter.rb
```

Run the scripted in-memory counter with:

```sh
bundle exec ruby examples/counter_memory.rb
```
