# Components

Components are reusable UI objects. They inherit from `Charming::Presentation::Component`, which itself inherits from `Charming::Presentation::View`, so they get assigns and rendering helpers.

## Rendering Components

Render components from templates or views with `render_component`:

```erb
<%= render_component Charming::Presentation::Components::List.new(
  items: ["Alpha", "Beta", "Gamma"],
  selected_index: 0,
  theme: theme
) %>
```

## Custom Components

Define a component by implementing `render`:

```ruby
class CounterComponent < Charming::Presentation::Component
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
| `TextArea` | Editable multiline text field with cursor movement, newline insertion, and vertical clipping. |
| `Form` | Huh-inspired form component with input, select, confirm, and note fields. |
| `List` | Selectable list with keyboard navigation and mouse support. |
| `Modal` | Overlay dialog with title, content, and help text. |
| `CommandPalette` | Fuzzy-search command input used internally by the framework. |
| `Markdown` | Markdown renderer backed by Kramdown with Rouge syntax highlighting for code blocks. |
| `Viewport` | Scrollable container for tall content lists. |
| `Spinner` | Animated progress indicator. |
| `ActivityIndicator` | Spinner-style activity indicator. |
| `Progressbar` | Text-based progress bar. |
| `Table` | Unicode-rendered data table with keyboard and mouse selection. |
| `KeyboardHandler` | Key-mapping mixin for custom components. |

## Markdown

Render Markdown with `Charming::Presentation::Components::Markdown`:

```erb
<%= render_component Charming::Presentation::Components::Markdown.new(
  content: readme,
  width: 72,
  theme: theme
) %>
```

Markdown parsing is handled by Kramdown. Code block tokenization is handled by Rouge. Charming owns the terminal rendering, wrapping, and theme styling.

Use it with `Viewport` for scrollable documentation or help screens:

```erb
<%= render_component Charming::Presentation::Components::Viewport.new(
  content: Charming::Presentation::Components::Markdown.new(content: readme, width: 72, theme: theme),
  width: 72,
  height: 20
) %>
```

Disable code syntax highlighting when plain code blocks are preferred:

```erb
<%= render_component Charming::Presentation::Components::Markdown.new(
  content: readme,
  syntax_highlighting: false
) %>
```

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

## Forms

Build session-backed forms from controllers with `form(:name)`. Form state is stored as primitive values under `session[:forms]`, so input survives fresh controller instances.

```ruby
class SignupController < Charming::Controller
  focus_ring :signup_form

  def show
    render :show, form: signup_form
  end

  def signup_form_submitted(values)
    # values => {name: "Ada", plan: "Pro", terms: true}
    navigate_to "/"
  end

  def signup_form_cancelled
    navigate_to "/"
  end

  private

  def signup_form
    form(:signup) do |f|
      f.input :name, label: "Name", placeholder: "Ada Lovelace", required: true
      f.textarea :bio, label: "Bio", height: 5, placeholder: "Tell us about yourself"
      f.select :plan, label: "Plan", options: ["Free", "Pro", "Team"]
      f.confirm :terms, label: "Accept terms?", required: true
      f.note "Enter submits from the last field. Escape cancels."
    end
  end
end
```

```erb
<%= render_component form %>
```

Form fields:

| Field | Behavior |
|-------|----------|
| `input` | Single-line text input. |
| `textarea` | Multiline text input. Plain Enter advances/submits; Shift+Enter inserts a newline when supported; Ctrl+J inserts a newline. |
| `select` | Single-choice picker. |
| `confirm` | Boolean yes/no field. |
| `note` | Static, non-focusable text. |

Keyboard behavior:

| Key | Behavior |
|-----|----------|
| `Tab` / `Shift+Tab` | Move between focusable fields. |
| `Enter` | Move to the next field, or submit from the last field. |
| `Shift+Enter` | Insert a newline in textarea fields when the terminal reports it distinctly. |
| `Ctrl+J` | Insert a newline in textarea fields. |
| `Ctrl+S` | Submit the form from any field. |
| `Escape` | Cancel the form. |
| `Up` / `Down` | Change select choices. |
| `Space`, `y`, `n` | Toggle or set confirm fields. |

Focused form results dispatch to controller hooks named after the focus slot: `signup_form_submitted(values)` and `signup_form_cancelled`.

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
