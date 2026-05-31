# Components

Components are reusable UI objects. They inherit from `Charming::Component`, which itself inherits from `Charming::View`, so they get assigns and rendering helpers.

## Rendering Components

Render components from templates or views with `render_component`:

```erb
<%= render_component Charming::Components::List.new(
  items: ["Alpha", "Beta", "Gamma"],
  selected_index: 0,
  theme: theme
) %>
```

## Custom Components

Define a component by implementing `render`:

```ruby
class CounterComponent < Charming::Component
  def render
    text "Count: #{count}", style: theme.info
  end
end
```

Assigns passed to `new` become reader methods:

```erb
<%= render_component CounterComponent.new(count: home.count, theme: theme) %>
```

## Built-In Components

| Component | Description |
|-----------|-------------|
| `TextInput` | Editable text field with cursor movement, selection, and insertion. |
| `List` | Selectable list with keyboard navigation and mouse support. |
| `Modal` | Overlay dialog with title, content, and help text. |
| `CommandPalette` | Fuzzy-search command input used internally by the framework. |
| `Viewport` | Scrollable container for tall content lists. |
| `Spinner` | Animated progress indicator. |
| `ActivityIndicator` | Spinner-style activity indicator. |
| `Progressbar` | Text-based progress bar. |
| `Table` | Unicode-rendered data table with keyboard and mouse selection. |
| `KeyboardHandler` | Key-mapping mixin for custom components. |

## Interaction

Interactive components should expose `handle_key(event)` and may expose `handle_mouse(event)`.

Return conventions:

| Return value | Meaning |
|--------------|---------|
| `:handled` | The component consumed the event. |
| `[:selected, object]` | The user selected an item. |
| `:cancelled` | The user cancelled the interaction. |
| `nil` | The component did not handle the event. |

Controllers dispatch events to focused components when no higher-priority handler consumes the event.

## Key Events

Use `Charming.key_of(event)` when component code needs the normalized key symbol:

```ruby
def handle_key(event)
  case Charming.key_of(event)
  when :enter then [:selected, selected_item]
  when :escape then :cancelled
  else nil
  end
end
```

## Mouse Events

Mouse-capable components can implement `handle_mouse(event)`:

```ruby
def handle_mouse(event)
  return nil unless event.click?

  select_at(event.y)
  :handled
end
```

Mouse events expose button, coordinates, modifier flags, and helpers such as `click?`, `scroll?`, and `release?`.
