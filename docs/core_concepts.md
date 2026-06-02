# Core Concepts

Charming is a Rails-inspired framework for terminal apps. Generated apps use routes, controllers, state objects, templates, layouts, components, themes, and a runtime that talks to a terminal backend.

## Architecture

Generated apps follow this flow:

```text
Application -> Router -> Controller -> Template/Layout -> Component -> UI
                         Runtime -> Renderer -> Terminal Backend
```

At runtime, the flow for a screen is:

```text
Route -> Controller action -> Template -> Layout -> Renderer -> Terminal frame
```

## Applications

An application owns the route table, session, themes, and task executor. Generated apps define the application class in `lib/my_app/application.rb`:

```ruby
module MyApp
  class Application < Charming::Application
    root File.expand_path("../..", __dir__)

    Charming::Presentation::UI::Theme.built_in_names.each do |theme_name|
      theme theme_name.to_sym, built_in: theme_name
    end

    default_theme :phosphor
  end
end
```

Routes are usually defined separately in `config/routes.rb`:

```ruby
MyApp::Application.routes do
  root "home#show"
end
```

## Controllers Are Ephemeral

Charming creates a fresh controller instance for each dispatch. A controller handles one action or event and returns a response.

Do not store durable state in controller instance variables. This is wrong for state that must survive multiple key presses:

```ruby
def increment
  @count ||= 0
  @count += 1
  render "Count: #{@count}"
end
```

Store durable state in an application state object instead:

```ruby
def increment
  counter.count += 1
  render "Count: #{counter.count}"
end

private

def counter
  state(:counter, CounterState)
end
```

`Controller#state` stores the state object in the application session and returns the same object on later dispatches.

## Views And Layouts

Generated controllers render views by symbol:

```ruby
def show
  render :show, home: home, palette: command_palette
end
```

For `HomeController`, `render :show` resolves:

```text
app/views/home/show_view.rb
```

Layouts wrap rendered views. Generated apps use a Ruby layout class:

```ruby
class ApplicationController < Charming::Controller
  layout Layouts::ApplicationLayout
end
```

That resolves:

```text
app/views/layouts/application_layout.rb
```

ERB templates remain available as a fallback. See [Controllers & Views](controllers_and_templates.md) and [Layouts](layouts.md) for details.

## Runtime

Most apps start through:

```ruby
Charming.run(MyApp::Application.new)
```

The runtime:

1. Enters the terminal alternate screen
2. Resolves the root route
3. Dispatches controller actions and events
4. Renders responses through a renderer
5. Reads key, mouse, resize, timer, and task events
6. Restores terminal state on quit or error

For tests, instantiate `Charming::Runtime` directly with `MemoryBackend`. See [Testing](testing.md).
