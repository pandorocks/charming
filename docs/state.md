# State

Application state classes hold durable in-memory TUI state. Controllers are created fresh per dispatch, so state that must survive key presses, timer ticks, task completions, and route renders belongs in state objects.

## ApplicationState

State classes inherit from `Charming::ApplicationState`, which includes `ActiveModel::Model` and `ActiveModel::Attributes`:

```ruby
module MyApp
  class HomeState < ApplicationState
    attribute :title, :string, default: "Home"
    attribute :count, :integer, default: 0
    attribute :status, :string, default: "Ready"
  end
end
```

Common attribute types include:

- `:string`
- `:integer`
- `:float`
- `:boolean`
- `:date`
- `:datetime`
- `:time`

## Session-Backed State

Use `Controller#state` to lazily create and cache state objects in the application session:

```ruby
def home
  state(:home, HomeState)
end
```

Subsequent calls with the same name return the same state object.

```ruby
def increment
  home.count += 1
  show
end
```

## Initial Attributes

Pass initial attributes through `model`:

```ruby
def counter
  state(:counter, CounterState, count: 10)
end
```

Initial attributes are only used when the state object is first created.

## Validations

Use normal ActiveModel validations:

```ruby
class CounterState < Charming::ApplicationState
  attribute :count, :integer, default: 0

  validate :count_gte_zero

  def count_gte_zero
    errors.add(:count, "must be >= 0") if count < 0
  end
end
```

Controller actions can call `valid?` and inspect `errors`:

```ruby
def save
  if form.valid?
    navigate_to "/"
  else
    render :edit, form: form
  end
end
```

## What Not To Store In Controllers

Avoid this for durable state:

```ruby
def increment
  @count ||= 0
  @count += 1
  render "Count: #{@count}"
end
```

The next dispatch receives a fresh controller instance, so the instance variable is not reliable application state.
