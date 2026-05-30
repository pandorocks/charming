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
  - `Charming::KeyEvent`
  - `Charming::ResizeEvent`
- Added internal terminal backends:
  - `Charming::Internal::Terminal::MemoryBackend`
  - `Charming::Internal::Terminal::TTYBackend`
- Added full repaint renderer:
  - `Charming::Internal::Renderer::FullRepaint`
- Added examples:
  - `examples/counter.rb`
  - `examples/counter_memory.rb`
- Added `Charming::UI` styling and layout foundation:
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
  - `Charming::View`
  - keyword assigns exposed as reader methods
  - view helpers for `style`, `text`, `box`, `row`, and `column`
  - controller rendering of view objects
- Added component foundation:
  - `Charming::Component`
  - component rendering from views
- Added first stateful component foundation:
  - `Charming::Components::TextInput`
  - mutable value and cursor state
  - key handling for insertion, cursor movement, backspace, and delete
- Added selectable list component foundation:
  - `Charming::Components::List`
  - selection movement and enter activation
  - custom item labels
  - fixed-height viewport rendering
- Added modal and command palette foundations:
  - `Charming::Components::Modal`
  - `Charming::Components::CommandPalette`
  - command filtering and selection
  - command palette controller helpers
  - command palette included in generated apps by default
- Added viewport and screen-aware rendering foundations:
  - `Charming::Components::Viewport`
  - `Charming::Screen`
  - backend screen dimensions passed through runtime to controllers and views
  - runtime re-rendering for `Charming::ResizeEvent`
  - TTY resize signal integration through `SIGWINCH`
  - viewport key handling for scrolling
- Added namespaced route resolution for generated apps.
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

Build toward robust larger-screen interaction primitives.

The command palette, viewport, and screen-aware rendering foundations are now in place. The next milestone is proving larger-screen interaction patterns with a scrollable example and timer-driven components.

Target direction:

```ruby
class ActivityView < Charming::View
  def render
    render_component Charming::Components::Viewport.new(content: log, height: 12)
  end
end
```

## Next

- Add an example that demonstrates a scrollable panel.
- Add a spinner component.
- Add a command/timer system for animation and polling.

## Later

- Harden runtime teardown for signals.
- Improve renderer with diffing.
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
