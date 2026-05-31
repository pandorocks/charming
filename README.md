# Charming

Charming is a Rails-inspired terminal user interface framework for Ruby 4+.

The project is currently in early foundation work. The intended architecture is a Rails-like public API over an internal terminal runtime, with explicit TTY-backed and in-memory backends.

```ruby
class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

class CounterController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "p", :open_command_palette
  key "q", :quit

  command "Increment counter", :increment
  command "Decrement counter", :decrement
  command "Quit app", :quit

  def show
    render "Count: #{counter.count}"
  end

  def increment
    counter.count += 1
    show
  end

  def decrement
    counter.count -= 1
    show
  end

  private

  def counter
    model(:counter, CounterModel)
  end
end

class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "charming"
```

Then execute:

```bash
bundle install
```

## Generating a TUI App

Create a runnable, gem-style Charming app with:

```bash
charming new weather_tui
cd weather_tui
bundle install
bundle exec weather_tui
```

Generated apps are namespaced and use Rails-like folders:

```text
app/controllers
app/models
app/views
app/components
config/routes.rb
exe/weather_tui
lib/weather_tui.rb
```

Inside an app, generate more code with:

```bash
charming generate controller forecast index
charming generate view forecast
charming generate component forecast_card
```

The `generate` command can also be shortened to `g`.

New apps include a command palette by default. Press `p` to open it, type to
filter commands, press `enter` to select, and press `escape` to close it.

## Routing And Params

Routes map paths to controller actions. Dynamic segments use `:name` and are
available in controllers through symbol-keyed `params`:

```ruby
class WeatherTui::Application < Charming::Application
  routes do
    root "home#show"
    screen "/cities/:id", to: "cities#show"
  end
end

class WeatherTui::CitiesController < Charming::Controller
  def show
    render "City #{params[:id]}"
  end
end
```

Dynamic params match a single path segment. Exact routes take precedence over
dynamic routes, so `/cities/new` can be defined separately from `/cities/:id`.

## Layouts And Partials

Generated apps include a Rails-style application layout at
`app/views/layouts/application.rb`. `ApplicationController` uses it by default:

```ruby
class ApplicationController < Charming::Controller
  layout Layouts::Application
end
```

Controller subclasses inherit their parent layout. Override it with another
layout class, or disable layout wrapping for a controller with `layout false`.

Layouts are `Charming::View` objects. Use `yield_content` to render the current
screen inside the layout:

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

Partials are class-based views too. Render them from another view with
`render_partial`:

```ruby
class HomeView < Charming::View
  def render
    render_partial HeaderPartial.new(title: "Home")
  end
end
```

## Themes

Applications can register named themes from bundled opencode-compatible JSON themes:

```ruby
class Application < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :opencode
end
```

Controllers can expose a nested theme picker in the command palette:

```ruby
command "Theme", :open_theme_palette
```

Themes can also be loaded from an opencode-format JSON file:

```ruby
theme :custom, from: "config/themes/custom.json"
```

Views and components use semantic tokens instead of hardcoded colors:

```ruby
text "Title", style: theme.primary.bold
text "Help", style: theme.muted
```

Bundled theme JSON files are vendored from opencode under the MIT license.

## Example App

The canonical example lives at `examples/demo_app`. It was created with
`charming new demo_app` and then extended to demonstrate application models,
components, command palettes, modal overlays, viewport scrolling, screen-aware
layout, and timer-driven spinners.

Run it with:

```bash
cd examples/demo_app
bundle install
bundle exec exe/demo_app
```

Useful keys:

```text
up/down     change the counter
j/k         scroll the activity log
p           open the command palette
q           quit
```

## Development

After checking out the repo, run:

```bash
bundle install
bin/check
```

Common development binstubs:

```bash
bin/rspec              # run specs
bin/format             # run Standard Ruby auto-formatting
bin/lint               # run Standard Ruby checks
bin/check              # run specs and Standard Ruby checks
bin/run-dummy          # run the dummy demo app
```

## License

The gem is available as open source under the terms of the MIT License.
