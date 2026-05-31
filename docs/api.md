# API Reference

This is a compact reference for Charming's current public API. Prefer these APIs in app code; classes under `Charming::Internal` are runtime internals.

## Application

Inherit from `Charming::Application`:

```ruby
class MyApp::Application < Charming::Application
  routes do
    root "home#show"
  end
end
```

Class APIs:

- `routes { ... }` defines routes with the router DSL.
- `root path` sets the application root path used for resolving relative files.
- `theme name, built_in: "phosphor"` registers a built-in JSON theme.
- `theme name, from: "config/themes/custom.json"` registers an app-local theme file.
- `default_theme name` sets the default theme.
- `theme_for name` resolves a theme object.

Instance APIs:

- `routes` returns the app router.
- `session` returns persistent app session state.
- `theme` returns the active theme.
- `use_theme name` switches the active theme.

Entrypoint:

```ruby
Charming.run(MyApp::Application.new)
```

## Router

Routes are usually defined in `config/routes.rb`:

```ruby
MyApp::Application.routes do
  root "home#show"
  screen "/users/:id", to: "users#show", title: "User"
end
```

DSL methods:

- `root "controller#action", title: "Home"` maps `/`.
- `screen "/path", to: "controller#action", title: nil` maps a screen path.

Resolution rules:

- Exact routes win over dynamic routes.
- Dynamic segments use `:name` and match one segment.
- Params are symbol-keyed, for example `params[:id]`.
- Params are URL-decoded.
- Missing routes raise `KeyError`.

Route objects expose:

- `path`
- `controller_class`
- `action`
- `title`
- `params`

## Controller

Inherit from `Charming::Controller` or your app's `ApplicationController`.

Class APIs:

- `key name, action` binds a key to an action.
- `command label, action = nil, &block` adds a command palette item.
- `timer name, every:, action:` dispatches a periodic timer while the route is active.
- `on_task name, action:` handles async task completion.
- `layout layout_class` wraps rendered output in a layout view.
- `layout false` disables inherited layout wrapping.
- `focus_ring *slots` defines tab-traversable focus slots.

Instance APIs:

- `dispatch(action)` calls an action and returns a response.
- `dispatch_key`, `dispatch_timer`, `dispatch_task`, and `dispatch_mouse` dispatch event-specific handlers.
- `render(body = "")` produces a render response.
- `navigate_to(path)` produces a navigation response.
- `quit` produces a quit response.
- `session` accesses the application session.
- `model(name, model_class, **attributes)` stores or returns a session-backed model.
- `run_task(name) { ... }` submits async work.
- `params` exposes current route params.
- `event` exposes the current key, timer, task, resize, or mouse event.
- `screen` exposes terminal dimensions.
- `theme` returns the current theme.
- `use_theme(name)` switches themes.
- `open_command_palette`, `close_command_palette`, and `command_palette` manage the command palette.
- `open_theme_palette` opens the theme picker.
- `focus_sidebar`, `focus_content`, `sidebar_focused?`, and `content_focused?` support generated layouts.

Controller instances are ephemeral. Store durable state in `ApplicationModel` objects through `model(...)`.

## ApplicationModel

Inherit from `Charming::ApplicationModel`:

```ruby
class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0
end
```

It includes ActiveModel model and attributes support, so typed attributes and validations are available.

## View

Inherit from `Charming::View` and implement `render`:

```ruby
class HomeView < Charming::View
  def render
    text title, style: theme.title
  end
end
```

Assigns passed to `new` become reader methods:

```ruby
HomeView.new(title: "Home", theme: theme)
```

View helpers:

- `text(value, style: nil)` renders text through an optional style.
- `box(value, style: nil)` renders boxed content.
- `row(*items, gap: 0)` joins rendered items horizontally.
- `column(*items, gap: 0)` joins rendered items vertically.
- `style` returns a new `Charming::UI::Style`.
- `theme` returns the assigned theme or default theme.
- `render_component(component)` renders a component.
- `render_partial(view)` renders another view.
- `yield_content` returns layout content.
- `layout_assigns` returns assigns used when composing layouts.

## Component

Inherit from `Charming::Component` for reusable UI objects. Components inherit view helpers and assign readers.

```ruby
class BadgeComponent < Charming::Component
  def render
    text label, style: theme.title
  end
end
```

Interactive components can implement:

- `handle_key(event)`
- `handle_mouse(event)`

Return conventions:

- `:handled` means the event was consumed.
- `[:selected, value]` means a value was selected.
- `:cancelled` means the interaction was cancelled.
- `nil` means the event was not handled.

Bundled components:

- `Charming::Components::TextInput`
- `Charming::Components::List`
- `Charming::Components::CommandPalette`
- `Charming::Components::Modal`
- `Charming::Components::Viewport`
- `Charming::Components::Spinner`
- `Charming::Components::Progressbar`
- `Charming::Components::ActivityIndicator`
- `Charming::Components::Table`

## UI

`Charming::UI` provides ANSI-aware layout helpers:

- `Charming::UI.style`
- `Charming::UI.join_horizontal(*blocks, gap: 0)`
- `Charming::UI.join_vertical(*blocks, gap: 0)`
- `Charming::UI.center(block, width:, height:)`
- `Charming::UI.place(block, width:, height:, top: 0, left: 0)`
- `Charming::UI.overlay(base, overlay, top: :center, left: :center)`
- `Charming::UI.visible_slice(line, start_column, width)`
- `Charming::UI::Width.measure(value)`
- `Charming::UI::Width.strip_ansi(value)`

Styles are immutable builders:

```ruby
style.foreground(:cyan).bold.border(:rounded).padding(1, 2).width(40)
```

Common style methods:

- `foreground` / `fg`
- `background` / `bg`
- `bold`, `faint`, `italic`, `underline`, `reverse`, `strikethrough`
- `padding`
- `border`
- `width`
- `height`
- `align`
- `render(value)`

## Events

Runtime events include:

- `Charming::KeyEvent`
- `Charming::ResizeEvent`
- `Charming::MouseEvent`
- `Charming::TimerEvent`
- `Charming::TaskEvent`

Use `Charming.key_of(event)` when component code needs the normalized key symbol.

## Responses

Controllers return response objects through helper methods:

- `render(...)` creates a render response.
- `navigate_to(path)` creates a navigation response.
- `quit` creates a quit response.

The runtime follows navigation responses, renders render responses, and exits on quit responses.

## Backends

Apps normally use `TTYBackend` through `Charming.run`. Tests should use `Charming::Internal::Terminal::MemoryBackend` to avoid real terminal I/O.

Backend and renderer classes under `Charming::Internal` are not the primary application API.
