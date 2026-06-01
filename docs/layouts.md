# Layouts

Layouts wrap screen views with shared UI such as sidebars, headers, footers, command palettes, and modal overlays.

Generated apps use Ruby layout classes and the declarative layout DSL:

```ruby
class ApplicationController < Charming::Controller
  layout Layouts::ApplicationLayout
  focus_ring :sidebar, :content
end
```

That resolves:

```text
app/views/layouts/application_layout.rb
```

ERB layouts remain available as a fallback with `layout "layouts/application"`.

## Layout Class

Layout classes inherit from `Charming::Presentation::View`:

```ruby
module MyApp
  module Layouts
    class ApplicationLayout < Charming::Presentation::View
      def render
        screen_layout(background: theme.background) do
          split :horizontal, gap: 1 do
            pane(:sidebar, width: 24, border: :rounded, padding: [1, 2]) do
              navigation
            end

            pane(:content, grow: 1, border: :rounded, padding: [1, 2]) do
              yield_content
            end
          end
        end
      end

      private

      def navigation
        column("Home", "Settings", gap: 1)
      end
    end
  end
end
```

## Layout Assigns

Layouts receive standard assigns:

| Assign | Purpose |
|--------|---------|
| `content` | The already-rendered screen body. |
| `screen` | Current terminal dimensions. |
| `controller` | Current controller instance. |
| `theme` | Active theme. |

Any assigns passed to the screen view are also available to the layout.

Use `yield_content` to place the current screen inside the layout.

## DSL Primitives

`screen_layout` creates a full-screen layout tree for the current terminal size.

```ruby
screen_layout(background: theme.background) do
  split :horizontal, gap: 1 do
    pane(:sidebar, width: 24) { "Sidebar" }
    pane(:content, grow: 1) { yield_content }
  end
end
```

Available primitives:

| Primitive | Purpose |
|-----------|---------|
| `screen_layout(background: nil) { ... }` | Render a full-screen layout using the current `screen`. |
| `split(:horizontal, gap: n) { ... }` | Divide space into left-to-right panes. |
| `split(:vertical, gap: n) { ... }` | Divide space into top-to-bottom panes. |
| `pane(:name, **options) { ... }` | Render content into an assigned rectangle. |
| `overlay(content, top: :center, left: :center)` | Draw content over the finished layout. |

Pane sizing options:

| Option | Behavior |
|--------|----------|
| `width: n` | Fixed outer width in a horizontal split. |
| `height: n` | Fixed outer height in a vertical split. |
| `grow: n` | Take remaining space, weighted by `n`. |
| no size | Equivalent to `grow: 1` inside a split. |

Pane styling options:

| Option | Behavior |
|--------|----------|
| `border: true` | Draw a normal border. |
| `border: :rounded` | Draw a named border style. |
| `padding: 1` | Add equal padding on all sides. |
| `padding: [1, 2]` | Add vertical and horizontal padding. |
| `style: theme.title` | Apply a base style. |
| `focus: true` | Include this pane in the layout's Tab focus ring. |
| `focused_style: theme.title` | Style the pane when it is focused. Defaults to `theme.title`. |
| `clip: true` | Clip content to the pane. This is the default. |
| `wrap: true` | Wrap long lines inside the pane. |

Pane dimensions are outer dimensions. Borders and padding are included in the assigned width and height.

Focusable panes are opt-in. Named panes are not focusable unless `focus: true` is set:

```ruby
screen_layout do
  split :horizontal, gap: 1 do
    pane(:files, width: 32, border: :rounded, focus: true) { files_panel }
    pane(:diff, grow: 1, border: :rounded, focus: true) { diff_panel }
  end
end
```

The first focusable pane starts focused. `Tab` cycles forward and `Shift+Tab` cycles backward. Command palettes and other modal scopes still take priority while open.

## Screen Views

Screens are Ruby view classes by default:

```ruby
module MyApp
  module Home
    class ShowView < Charming::Presentation::View
      def render
        column(
          text(home.title, style: theme.title),
          text("Press p for commands, q to quit.", style: theme.muted),
          gap: 1
        )
      end
    end
  end
end
```

The controller can still render by action name:

```ruby
def show
  render :show, home: home, palette: command_palette
end
```

For `HomeController`, that resolves `MyApp::Home::ShowView` before falling back to ERB templates.

## Responsive Layouts

Use normal Ruby methods and `screen` dimensions:

```ruby
def render
  screen_layout do
    split(narrow? ? :vertical : :horizontal, gap: 1) do
      pane(:sidebar, **sidebar_options, border: :rounded, padding: [1, 2]) do
        navigation
      end

      pane(:content, grow: 1, border: :rounded, padding: [1, 2]) do
        yield_content
      end
    end
  end
end

private

def narrow?
  screen.narrow?(below: 72, min_height: 20)
end

def sidebar_options
  narrow? ? {height: [screen.height / 3, 5].max} : {width: 24}
end
```

## Modal Overlays

Use `overlay` inside `screen_layout` for command palettes, dialogs, tooltips, or toasts:

```ruby
def render
  screen_layout(background: theme.background) do
    split :horizontal, gap: 1 do
      pane(:sidebar, width: 24, border: :rounded) { navigation }
      pane(:content, grow: 1, border: :rounded) { yield_content }
    end

    overlay command_palette_modal if command_palette_modal
  end
end

private

def command_palette_modal
  return unless palette

  render_component Charming::Presentation::Components::Modal.new(
    title: "Command palette",
    content: palette,
    help: "Type to filter. Enter selects. Escape closes.",
    width: 52,
    theme: theme
  )
end
```

## Lower-Level Helpers

The DSL sits above the lower-level string helpers. Use these inside panes and screen views:

| Helper | Purpose |
|--------|---------|
| `text(value, style: nil)` | Render styled text. |
| `box(value, style: nil)` | Style or border a block manually. |
| `row(*items, gap: 0)` | Join blocks side by side. |
| `column(*items, gap: 0)` | Stack blocks vertically. |
| `render_component(component)` | Render reusable components. |

Use `Charming::Presentation::UI.place`, `center`, and `overlay` only when you need lower-level canvas control.

## Style Chaining

`Charming::Presentation::UI::Style` objects are immutable and chainable:

```ruby
panel_style = Charming::Presentation::UI.style
  .foreground(:bright_cyan)
  .background("#101820")
  .bold
  .border(:rounded, foreground: :bright_magenta)
  .padding(1, 2)
  .width(40)
  .align(:center)

box("System ready", style: panel_style)
```

Common style methods:

| Method | Purpose |
|--------|---------|
| `foreground(color)` / `fg(color)` | Set text color. |
| `background(color)` / `bg(color)` | Set background color. |
| `bold`, `faint`, `italic`, `underline`, `reverse`, `strikethrough` | Add text attributes. |
| `padding(1)`, `padding(1, 2)`, `padding(1, 2, 1, 2)` | Add CSS-like padding. |
| `border(:normal | :rounded | :thick | :double)` | Add a border. |
| `border(..., sides: [:top, :bottom])` | Draw only specific sides. |
| `width(value)` | Set content width. |
| `height(value)` | Set content height. |
| `align(:left | :center | :right)` | Align content within width. |

Colors can be named symbols (`:cyan`, `:bright_white`), 0-255 indexed colors, or truecolor hex strings (`"#ff00aa"`).
