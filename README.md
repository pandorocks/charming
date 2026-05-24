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
app/controllers/weather_tui
app/models/weather_tui
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

New apps include a command palette by default. Press `p` to open it, type to
filter commands, press `enter` to select, and press `escape` to close it.

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rake
```

## License

The gem is available as open source under the terms of the MIT License.
