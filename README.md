# Charming

Charming is a Rails-inspired terminal user interface framework for Ruby.

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
  key "q", :quit

  def show
    session[:count] ||= 0
    render "Count: #{session[:count]}"
  end

  def increment
    session[:count] += 1
    render "Count: #{session[:count]}"
  end

  def decrement
    session[:count] -= 1
    render "Count: #{session[:count]}"
  end
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
app/controllers/weather_tui
app/views/weather_tui
app/components/weather_tui
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

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rake
```

## License

The gem is available as open source under the terms of the MIT License.
