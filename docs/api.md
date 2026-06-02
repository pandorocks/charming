# API Reference

This is a compact reference for Charming's current public API. Prefer these APIs in app code. Classes under `Charming::Internal` are runtime internals and are documented mainly for testing.

For tutorial-style explanations, see [Getting Started](getting_started.md). For topic guides, see the [docs index](README.md).

## Application

Inherit from `Charming::Application`:

```ruby
class MyApp::Application < Charming::Application
  root File.expand_path("../..", __dir__)
end
```

Generated apps define routes separately in `config/routes.rb`:

```ruby
MyApp::Application.routes do
  root "home#show"
end
```

Routes can also be defined inline on the application class:

```ruby
class MyApp::Application < Charming::Application
  root File.expand_path("../..", __dir__)

  routes do
    root "home#show"
  end
end
```

Class APIs:

- `routes { ... }` defines routes with the router DSL.
- `root path` sets the application root path used for resolving relative files and templates.
- `theme name, built_in: "phosphor"` registers a built-in JSON theme.
- `theme name, from: "config/themes/custom.json"` registers an app-local theme file.
- `default_theme name` sets the default theme.
- `theme_for name` resolves a theme object.
- `namespace` returns the application namespace used for controller and template binding lookup.

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

- `key name, action, scope: :content` binds a content-pane key to an action.
- `key name, action, scope: :global` binds an app-level shortcut.
- `command label, action = nil, &block` adds a command palette item.
- `timer name, every:, action:` dispatches a periodic timer while the route is active.
- `on_task name, action:` handles async task completion.
- `layout layout_class` wraps rendered output in a class-based layout view.
- `layout "layouts/application"` wraps rendered output in an ERB template layout fallback.
- `layout false` disables inherited layout wrapping.
- `focus_ring *slots` defines tab-traversable focus slots.

Instance APIs:

- `dispatch(action)` calls an action and returns a response.
- `dispatch_key`, `dispatch_timer`, `dispatch_task`, and `dispatch_mouse` dispatch event-specific handlers.
- `render(body = "", **assigns)` produces a render response.
- `render "literal"` renders a literal string.
- `render :show, **assigns` renders a conventional Ruby view class, falling back to `app/views/<controller>/show.tui.erb` or `.txt.erb`.
- `render view_object` renders a class-based view or component object.
- `render_template(name, **assigns)` renders an explicit template path under `app/views`.
- `navigate_to(path)` produces a navigation response.
- `quit` produces a quit response.
- `session` accesses the application session.
- `state(name, state_class, **attributes)` stores or returns a session-backed state object.
- `run_task(name) { ... }` submits async work.
- `params` exposes current route params.
- `event` exposes the current key, timer, task, resize, or mouse event.
- `screen` exposes terminal dimensions.
- `theme` returns the current theme.
- `use_theme(name)` switches themes.
- `open_command_palette`, `close_command_palette`, and `command_palette` manage the command palette.
- `open_theme_palette` opens the theme picker.
- `command_palette_open?` returns whether a command or theme palette is open.
- `focus_sidebar`, `focus_content`, `sidebar_focused?`, and `content_focused?` support generated layouts.

Controller instances are ephemeral. Store durable state in `ApplicationState` objects through `state(...)`.

## ApplicationState

Inherit from `Charming::ApplicationState`:

```ruby
class CounterState < Charming::ApplicationState
  attribute :count, :integer, default: 0
end
```

It includes ActiveModel model and attributes support, so typed attributes and validations are available.

Common attribute types include `:string`, `:integer`, `:float`, `:boolean`, `:date`, `:datetime`, and `:time`.

## Views And Templates

Class-based views are the default. Inherit from `Charming::Presentation::View` and implement `render`:

```ruby
module MyApp
  module Home
    class ShowView < Charming::Presentation::View
      def render
        text title, style: theme.title
      end
    end
  end
end
```

For `render :show` in `HomeController`, Charming resolves `MyApp::Home::ShowView` first.

## Template Fallback

`Charming::Presentation::Templates` resolves and renders ERB templates under `app/views` when no conventional view class exists or when `render_template` is used.

Template APIs:

- `Charming::Presentation::Templates.register(extension, handler)` registers a template handler.
- `Charming::Presentation::Templates.resolve(name, root:)` resolves a template from an app root.
- `Charming::Presentation::Templates::MissingTemplateError` is raised when no candidate file exists.

Registered extensions:

- `.tui.erb`
- `.txt.erb`

For `Templates.resolve("home/show", root: app_root)`, Charming searches:

```text
app/views/home/show.tui.erb
app/views/home/show.txt.erb
```

`.tui.erb` is preferred before `.txt.erb`.

Template handlers implement:

```ruby
def self.render(path, view)
  # return rendered string
end
```

## TemplateView

`Charming::Presentation::TemplateView` renders resolved templates with normal view helpers and assigns:

```ruby
template = Charming::Presentation::Templates.resolve("home/show", root: app_root)
view = Charming::Presentation::TemplateView.new(template: template, home: home, theme: theme)
view.render
```

Constructor:

- `template:` is a resolved template.
- `namespace:` optionally controls constant lookup during template binding.
- `**assigns` become reader methods available inside the template.

Instance APIs:

- `render` renders the template to a string.
- `template_binding` returns the binding used by ERB handlers.

Generated controllers usually do not instantiate `TemplateView` directly. Use Ruby views with `render :show`, or `render_template "path"` for ERB fallback content.

## View

Inherit from `Charming::Presentation::View` and implement `render`:

```ruby
class HomeView < Charming::Presentation::View
  def render
    text title, style: theme.title
  end
end
```

Assigns passed to `new` become reader methods:

```ruby
HomeView.new(title: "Home", theme: theme)
```

View and template helpers:

- `text(value, style: nil)` renders text through an optional style.
- `box(value, style: nil)` renders boxed or styled content.
- `box(style: style) { ... }` captures nested helper output into a styled block.
- `row(*items, gap: 0)` joins rendered items horizontally.
- `column(*items, gap: 0)` joins rendered items vertically.
- `screen_layout(background: nil) { ... }` renders a full-screen declarative layout tree with `split`, `pane`, and `overlay`. `pane` blocks may accept a `Charming::Presentation::Layout::Rect` argument for the pane's inner content area.
- `style` returns a new `Charming::Presentation::UI::Style`.
- `theme` returns the assigned theme or default theme.
- `render_component(component)` renders a component.
- `render_partial(view)` renders another view.
- `yield_content` returns layout content.
- `layout_assigns` returns assigns used when composing layouts.
- `focused?(slot)` delegates focus lookup to the controller assign.

## Component

Inherit from `Charming::Presentation::Component` for reusable UI objects. Components inherit view helpers and assign readers.

```ruby
class BadgeComponent < Charming::Presentation::Component
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

- `Charming::Presentation::Components::TextInput`
- `Charming::Presentation::Components::TextArea`
- `Charming::Presentation::Components::Form`
- `Charming::Presentation::Components::List`
- `Charming::Presentation::Components::CommandPalette`
- `Charming::Presentation::Components::CommandPaletteModal`
- `Charming::Presentation::Components::Modal`
- `Charming::Presentation::Components::Markdown`
- `Charming::Presentation::Components::Viewport`
- `Charming::Presentation::Components::Spinner`
- `Charming::Presentation::Components::Progressbar`
- `Charming::Presentation::Components::ActivityIndicator`
- `Charming::Presentation::Components::Table`
- `Charming::Presentation::Components::KeyboardHandler`

ActivityIndicator constructor options include `width:`, `label:`, `index:`, `seed:`, `chars:`, `gradient:`, `label_style:`, `max_width:`, and `fallback_label:`.

Form component constructor:

- `fields:` array of form field objects.
- `state:` mutable primitive state hash, usually from `session[:forms]`.
- `theme:` optional `Charming::Presentation::UI::Theme`.

Form field classes:

- `Charming::Presentation::Components::Form::Input`
- `Charming::Presentation::Components::Form::Textarea`
- `Charming::Presentation::Components::Form::Select`
- `Charming::Presentation::Components::Form::Confirm`
- `Charming::Presentation::Components::Form::Note`

Controller helper:

```ruby
form(:signup) do |f|
  f.input :name, required: true
  f.textarea :bio, height: 5
  f.select :plan, options: ["Free", "Pro"]
  f.confirm :terms, required: true
end
```

TextArea component constructor:

- `value:` current multiline string.
- `placeholder:` rendered when value is empty.
- `width:` optional visible columns per line.
- `height:` optional visible rows.
- `cursor:` absolute cursor offset into `value`.
- `offset:` first visible row.
- `preferred_column:` remembered column for up/down movement.

Textarea keys:

- Plain `Enter` is left for the form to advance or submit.
- `Shift+Enter` inserts a newline when the terminal reports it distinctly.
- `Ctrl+J` inserts a newline reliably.
- `Ctrl+S` submits the form from any field.

Focused component result hooks:

- `[:submitted, values]` calls `<focus_slot>_submitted(values)` when defined.
- `[:selected, value]` calls `<focus_slot>_selected(value)` when defined.
- `:cancelled` calls `<focus_slot>_cancelled` when defined.

Markdown component constructor:

- `content:` Markdown source string.
- `width:` optional terminal width used for paragraph wrapping.
- `theme:` optional `Charming::Presentation::UI::Theme`.
- `syntax_highlighting:` controls Rouge-backed code block highlighting, defaulting to `true`.

Markdown parsing uses Kramdown. Syntax highlighting uses Rouge. Charming maps parsed nodes and Rouge tokens to terminal text through `Charming::Presentation::UI::Style` and theme tokens.

## UI

`Charming::Presentation::UI` provides ANSI-aware layout helpers:

- `Charming::Presentation::UI.style`
- `Charming::Presentation::UI.join_horizontal(*blocks, gap: 0)`
- `Charming::Presentation::UI.join_vertical(*blocks, gap: 0)`
- `Charming::Presentation::UI.center(block, width:, height:)`
- `Charming::Presentation::UI.place(block, width:, height:, top: 0, left: 0, background: nil)`
- `Charming::Presentation::UI.overlay(base, overlay, top: :center, left: :center)`
- `Charming::Presentation::UI.visible_slice(line, start_column, width)`
- `Charming::Presentation::UI::Width.measure(value)`
- `Charming::Presentation::UI::Width.strip_ansi(value)`

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

## Themes

Theme tokens return `Charming::Presentation::UI::Style` objects:

- `text`
- `title`
- `muted`
- `border`
- `selected`
- `info`
- `warn`

Themes can be loaded with `theme name, built_in:` or `theme name, from:` on the application class.

## Events

Runtime events include:

- `Charming::Events::KeyEvent`
- `Charming::Events::ResizeEvent`
- `Charming::Events::MouseEvent`
- `Charming::Events::TimerEvent`
- `Charming::Events::TaskEvent`

Use `Charming.key_of(event)` when component code needs the normalized key symbol.

## Responses

Controllers return response objects through helper methods:

- `render(...)` creates a render response.
- `navigate_to(path)` creates a navigation response.
- `quit` creates a quit response.

Response factories:

- `Charming::Response.render(body)`
- `Charming::Response.navigate(path)`
- `Charming::Response.quit`

Response predicates:

- `response.navigate?`
- `response.quit?`

Response attributes:

- `kind`
- `body`
- `path`

The runtime follows navigation responses, renders render responses, and exits on quit responses.

## Runtime And Testing Backends

Apps normally use `TTYBackend` through `Charming.run`. Tests should use `Charming::Internal::Terminal::MemoryBackend` to avoid real terminal I/O.

For testing patterns, see [Testing](testing.md).
