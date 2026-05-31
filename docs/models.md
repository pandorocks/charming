# Models

Application models hold durable app state. Controllers are created fresh per dispatch, so state that must survive key presses, timer ticks, task completions, and route renders belongs in models.

## ApplicationModel

Models inherit from `Charming::ApplicationModel`, which includes `ActiveModel::Model` and `ActiveModel::Attributes`:

```ruby
module MyApp
  class HomeModel < ApplicationModel
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

Use `Controller#model` to lazily create and cache models in the application session:

```ruby
def home
  model(:home, HomeModel)
end
```

Subsequent calls with the same name return the same model object.

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
  model(:counter, CounterModel, count: 10)
end
```

Initial attributes are only used when the model is first created.

## Validations

Use normal ActiveModel validations:

```ruby
class CounterModel < Charming::ApplicationModel
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
