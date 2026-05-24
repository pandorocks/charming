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

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rake
```

## License

The gem is available as open source under the terms of the MIT License.
