# Getting Started

Charming is a Rails-inspired terminal UI framework for Ruby 4+. A Charming app is a small Ruby gem with routes, controllers, models, views, components, and an internal terminal runtime.

## Create An App

```sh
charming new weather_tui
cd weather_tui
bundle install
bundle exec weather_tui
```

Generated apps use Rails-like folders:

```text
app/components
app/controllers
app/models
app/views
app/views/layouts
config/routes.rb
exe/weather_tui
lib/weather_tui.rb
lib/weather_tui/application.rb
spec
```

The executable boots the app with:

```ruby
Charming.run(WeatherTui::Application.new)
```

## Routes

Routes live in `config/routes.rb`:

```ruby
WeatherTui::Application.routes do
  root "home#show"
  screen "/cities/:id", to: "cities#show", title: "City"
end
```

`root` maps `/` to a controller action. `screen` maps a path to `controller#action`.

Dynamic segments are available as symbol-keyed controller params:

```ruby
class WeatherTui::CitiesController < WeatherTui::ApplicationController
  def show
    render "City #{params[:id]}"
  end
end
```

Dynamic params match one path segment. Exact routes win over dynamic routes, so `/cities/new` can be defined separately from `/cities/:id`.

## Controllers

Controllers handle app events and render responses. A fresh controller instance is created for each dispatch, so persistent state belongs in application models, not controller instance variables.

```ruby
module WeatherTui
  class HomeController < ApplicationController
    key "up", :increment
    key "down", :decrement
    key "p", :open_command_palette
    key "q", :quit

    command "Refresh", :refresh
    command "Quit app", :quit

    def show
      render HomeView.new(home: home, palette: command_palette, screen: screen, theme: theme)
    end

    def increment
      home.count += 1
      show
    end

    def decrement
      home.count -= 1
      show
    end

    private

    def home
      model(:home, HomeModel)
    end
  end
end
```

Useful controller APIs:

- `key "q", :quit` dispatches a key to an action.
- `command "Label", :action` adds a command palette item.
- `render value` renders a string, view, or component.
- `navigate_to "/path"` changes routes.
- `quit` exits the runtime.
- `params` exposes route params.
- `screen.width` and `screen.height` expose terminal dimensions.
- `model(:name, ModelClass)` stores and reuses app state in the application session.

## Models

Models inherit from `Charming::ApplicationModel`, which uses ActiveModel attributes and validations.

```ruby
module WeatherTui
  class HomeModel < ApplicationModel
    attribute :title, :string, default: "Weather"
    attribute :count, :integer, default: 0
  end
end
```

Use models for state that must survive key presses, timers, task completions, and route renders.

## Views

Views inherit from `Charming::View`. Keyword assigns become reader methods.

```ruby
module WeatherTui
  class HomeView < Charming::View
    def render
      column(title, counter, gap: 1)
    end

    private

    def title
      text home.title, style: theme.title
    end

    def counter
      text "Count: #{home.count}", style: theme.muted
    end
  end
end
```

Common helpers:

- `text(value, style:)` renders styled text.
- `box(value, style:)` renders a styled box.
- `row(*items, gap:)` joins items horizontally.
- `column(*items, gap:)` stacks items vertically.
- `render_component(component)` renders a component.
- `render_partial(view)` renders another view object.
- `style` creates a `Charming::UI::Style`.
- `theme` exposes the current app theme.

## Layouts

Generated apps use a controller layout:

```ruby
class ApplicationController < Charming::Controller
  layout Layouts::Application
end
```

Layouts are views. Use `yield_content` to render the current screen inside the layout.

```ruby
module WeatherTui
  module Layouts
    class Application < Charming::View
      def render
        Charming::UI.center(yield_content, width: screen.width, height: screen.height)
      end
    end
  end
end
```

## Components

Components inherit from `Charming::Component`, which itself inherits from `Charming::View`. Components can render text and can optionally handle input.

```ruby
class CounterComponent < Charming::Component
  def render
    text "Count: #{count}", style: theme.info
  end
end
```

Render one from a view:

```ruby
render_component CounterComponent.new(count: home.count, theme: theme)
```

Interactive components should expose `handle_key(event)`. Existing components return:

- `:handled` when a key was consumed.
- `[:selected, value]` when a value was selected.
- `:cancelled` when cancelled.
- `nil` when not handled.

## Command Palette

Generated apps bind `p` to `open_command_palette` and add commands in `ApplicationController`:

```ruby
command "Home" do
  navigate_to "/"
end

command "Theme", :open_theme_palette
command "Quit app", :quit
```

When the palette is open it receives key events before normal controller key bindings.

## Timers And Tasks

Timers dispatch periodically while a route is active:

```ruby
timer :clock, every: 0.5, action: :tick

def tick
  home.index += 1
  show
end
```

Tasks run work through the app task executor and dispatch a `TaskEvent` when complete:

```ruby
on_task :refresh_home, action: :refresh_loaded

def refresh
  run_task(:refresh_home) { "Loaded" }
  show
end

def refresh_loaded
  home.message = event.error? ? event.error.message : event.value
  show
end
```

## Themes

Applications can register built-in themes:

```ruby
class WeatherTui::Application < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor
end
```

Views and components should prefer semantic theme styles:

```ruby
text "Title", style: theme.title
text "Help", style: theme.muted
```

## Generate More Files

Inside an app:

```sh
charming generate screen forecast
charming generate controller forecast show
charming generate view forecast
charming generate component forecast_card
```

`generate` can be shortened to `g`.

## Run Tests

Generated apps include RSpec specs. Run them with:

```sh
bundle exec rspec
```

For framework development, use:

```sh
bin/check
```
