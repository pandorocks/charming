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

Pass initial attributes through `state`:

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

## Form State

Use `Controller#form` for session-backed terminal forms. Charming stores only primitive form data under `session[:forms]`, then rebuilds form components on each dispatch.

```ruby
def signup_form
  form(:signup) do |f|
    f.input :name, required: true
    f.textarea :bio, height: 5
    f.select :plan, options: ["Free", "Pro"]
    f.confirm :terms, required: true
  end
end
```

Textarea fields store their editing state alongside the value:

```ruby
session[:forms][:signup] = {
  values: {bio: "Line one\nLine two"},
  fields: {bio: {cursor: 18, offset: 0, preferred_column: 8}},
  errors: {},
  focus_index: 0
}
```

On submit, the focused form returns `[:submitted, values]` and dispatches to a hook matching the focus slot:

```ruby
focus_ring :signup_form

def signup_form_submitted(values)
  profile.assign_attributes(values)
  profile.valid? ? navigate_to("/") : show
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
