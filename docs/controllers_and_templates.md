# Controllers & Templates

Controllers dispatch actions, bind input, navigate between routes, run background tasks, and render responses.

## Controller Actions

Generated controllers inherit from the app's `ApplicationController`:

```ruby
module MyApp
  class HomeController < ApplicationController
    def show
      render :show, home: home, palette: command_palette
    end

    private

    def home
      state(:home, HomeState)
    end
  end
end
```

`render :show` resolves the template for the current controller action:

```text
app/views/home/show.tui.erb
```

## Rendering

Controller render forms:

| Form | Behavior |
|------|----------|
| `render :show, **assigns` | Renders `app/views/<controller>/show.tui.erb` or `.txt.erb`. |
| `render_template "custom/page", **assigns` | Renders an explicit template path under `app/views`. |
| `render "literal text"` | Renders a literal string. |
| `render view_object` | Renders a class-based view or component object. |

Assigns passed to `render` become methods in the template:

```ruby
render :show, home: home, palette: command_palette
```

```erb
<%= text home.title, style: theme.title %>
```

Templates also receive `screen`, `controller`, and `theme` assigns.

## Template Files

Charming resolves templates from `app/views`.

For `render :show` in `HomeController`, Charming searches:

```text
app/views/home/show.tui.erb
app/views/home/show.txt.erb
```

`.tui.erb` is preferred before `.txt.erb`.

## Template Helpers

Templates share the same helper set as class-based views:

| Helper | Purpose |
|--------|---------|
| `text(value, style: nil)` | Render styled text. |
| `box(value, style: nil)` | Style or border a block. |
| `row(*items, gap: 0)` | Join blocks side by side. |
| `column(*items, gap: 0)` | Stack blocks vertically. |
| `render_component(component)` | Render a component or partial object. |
| `render_partial(partial)` | Alias for `render_component`. |
| `yield_content` | Render wrapped screen content in a layout. |
| `focused?(slot)` | Ask the controller whether a focus slot is active. |

## Key Bindings

Bind key events to controller actions:

```ruby
key "up", :increment
key "down", :decrement
key "q", :quit, scope: :global
```

Content-scoped bindings only run when content focus is active. Global bindings run from any focused pane.

## Command Palette

Add commands with a method name or block:

```ruby
command "Refresh", :refresh

command "Home" do
  navigate_to "/"
end
```

Generated apps bind `p` globally to `open_command_palette` and include commands for theme switching and quit.

## Navigation And Quit

Use controller helpers to change app flow:

```ruby
navigate_to "/settings"
quit
```

These produce `Charming::Response` objects that the runtime interprets.

## Timers

Timers dispatch periodically while the current route is active:

```ruby
timer :clock, every: 0.5, action: :tick

def tick
  clock.now = Time.now
  show
end
```

## Background Tasks

Register a task handler and dispatch work with `run_task`:

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

Task results arrive as `Charming::Events::TaskEvent` with `value`, `error`, and `error?`.

## Class-Based Views

Generated apps use templates by default, but class-based views still work:

```ruby
class HomeView < Charming::Presentation::View
  def render
    text title, style: theme.title
  end
end
```

```ruby
render HomeView.new(title: "Home", theme: theme)
```
