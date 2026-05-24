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
- Added RSpec coverage for routing, controller dispatch, runtime behavior, backends, renderer, and UI styling/layout.

## Current Milestone

Build the Rails-like view layer on top of `Charming::UI`.

The goal is to move rendering out of controllers so controllers handle actions/state and views handle presentation.

Target direction:

```ruby
class CounterController < Charming::Controller
  def show
    session[:count] ||= 0
    render CounterView.new(count: session[:count])
  end
end

class CounterView < Charming::View
  def render
    box(style: :card) do
      text "Charming counter", style: :title
      text "Count: #{count}", style: :count
      text "Press q to quit", style: :muted
    end
  end
end
```

## Next

- Add `Charming::View`.
- Allow `Controller#render` to accept objects that respond to `render`.
- Add keyword assigns to views.
- Add basic view helpers:
  - `text`
  - `box`
  - `row`
  - `column`
  - `style`
- Update `examples/counter.rb` to use a view object.
- Add specs for view rendering and controller/view integration.

## Later

- Add `Charming::Component`.
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
