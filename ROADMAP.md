# Roadmap

## Product Direction

Charming is a Rails-inspired terminal user interface framework for Ruby.

The public API should feel familiar to Rails developers: applications, routes, controllers, views, components, rendering, and conventions. Internally, Charming keeps terminal I/O behind a backend seam so the runtime, tests, components, and application code do not depend directly on TTY gems.

## Architectural Principles

- Prefer Rails-like public concepts over Elm-style public concepts.
- Keep terminal input/output behind internal backend interfaces.
- Keep the in-memory backend as a first-class test backend.
- Keep styling and layout usable independently of the runtime.
- Keep dependencies explicit and minimal.
- Make examples and tests part of the deliverable, not afterthoughts.

## Completed

- Generated a conventional Bundler gem structure.
- Switched testing to RSpec.
- Added RuboCop and a default `rake` task.
- Set Ruby floor to `>= 3.2.0`.
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
- Added Rails-like view foundation:
  - `Charming::View`
  - keyword assigns exposed as reader methods
  - view helpers for `style`, `text`, `box`, `row`, and `column`
  - controller rendering of view objects
- Added component foundation:
  - `Charming::Component`
  - component rendering from views
- Added RSpec coverage for routing, controller dispatch, runtime behavior, backends, renderer, and UI styling/layout.

## Current Milestone

Design the first stateful component.

The goal is to let reusable components handle both rendering and terminal input without leaking runtime internals into application code.

Target direction:

```ruby
class TextInputComponent < Charming::Component
  key "left", :move_left
  key "right", :move_right
  key "backspace", :delete_before_cursor

  def render
    # ...
  end
end
```

## Next

- Decide how stateful components receive key events.
- Decide how parent controllers/views route events to focused components.
- Add the first stateful component: `TextInputComponent`.
- Add specs for component state, input handling, and rendering.

## Later

- Add first reusable components:
  - text input
  - viewport
  - spinner
  - selectable list
- Add command/timer system.
- Add resize event handling.
- Harden runtime teardown for signals.
- Improve renderer with diffing.
- Expand layout features:
  - wrapping
  - clipping
  - vertical alignment
  - min/max width and height
  - viewport-aware layout
- Add app file conventions:
  - `app/controllers`
  - `app/views`
  - `app/components`
  - `config/routes.rb`
- Add generators later if the conventions stabilize.
- Expand examples and documentation.

## Verification

Run the full project check with:

```sh
bundle exec rake
```

Run the interactive counter with:

```sh
bundle exec ruby examples/counter.rb
```

Run the scripted in-memory counter with:

```sh
bundle exec ruby examples/counter_memory.rb
```
