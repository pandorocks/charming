# Layouts

Layouts wrap screen templates with shared UI such as sidebars, headers, footers, command palettes, and modal overlays.

Generated apps use a template layout:

```ruby
class ApplicationController < Charming::Controller
  layout "layouts/application"
  focus_ring :sidebar, :content
end
```

That resolves:

```text
app/views/layouts/application.tui.erb
```

Class-based layout views are also supported with `layout Layouts::Application`.

## Layout Assigns

Layouts receive standard assigns:

| Assign | Purpose |
|--------|---------|
| `content` | The already-rendered screen body. |
| `screen` | Current terminal dimensions. |
| `controller` | Current controller instance. |
| `theme` | Active theme. |

Any assigns passed to the screen template are also available to the layout.

Use `yield_content` to place the current screen inside the layout:

```erb
<%= box(yield_content, style: theme.border.border(:rounded).padding(1, 2)) %>
```

## Basic Frame

Use `row` for side-by-side panels and `Charming::Presentation::UI.place` to fill the terminal canvas:

```erb
<%
sidebar = box("Home\nSettings", style: theme.border.border(:rounded).padding(1, 2).width(20))
main = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
frame = row(sidebar, main, gap: 1)
%><%= Charming::Presentation::UI.place(frame, width: screen.width, height: screen.height) %>
```

## Layout Tool Layers

Charming has two layers of layout tools:

| Layer | Use For | APIs |
|-------|---------|------|
| View composition | Building blocks relative to each other | `row`, `column`, `box`, `text` |
| Spatial placement | Placing blocks on fixed terminal canvases | `Charming::Presentation::UI.center`, `place`, `overlay` |

All layout helpers are ANSI-aware and account for terminal display width.

## Stacked Layouts

Use `column` for vertical screens, forms, and status panels:

```erb
<%= column(
  text("Create Project", style: theme.title),
  row(text("Name", style: theme.muted.width(12)), text(project.name, style: theme.text)),
  row(text("Owner", style: theme.muted.width(12)), text(project.owner, style: theme.text)),
  text("Tab moves focus. Enter saves.", style: theme.muted),
  gap: 1
) %>
```

## Sidebars And Split Panes

Give each panel an explicit width so multiline content aligns correctly:

```erb
<%
sidebar = box(nav_items, style: theme.border.border(:rounded).padding(1, 2).width(22))
details = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
%><%= row(sidebar, details, gap: 1) %>
```

Generated app layouts use route titles and focus state to build sidebar navigation:

```erb
<%
nav_items = controller.application.routes.all.each_with_index.map do |route, index|
  selected = controller.sidebar_focused? && index == controller.sidebar_index
  style = selected ? theme.selected : theme.muted
  text route.title, style: style
end
%><%= column(*nav_items) %>
```

## Responsive Layouts

Branch on `screen.width` and `screen.height`:

```erb
<%
narrow = screen.width < 72 && screen.height >= 20
body = narrow ? column(sidebar, main_content, gap: 1) : row(sidebar, main_content, gap: 1)
%><%= Charming::Presentation::UI.place(body, width: screen.width, height: screen.height) %>
```

## Centered Dialogs

Use `Charming::Presentation::UI.center` to put a block in the middle of a fixed-size canvas:

```erb
<%
dialog = box(
  column(
    text("Delete project?", style: theme.title),
    text("This cannot be undone.", style: theme.warn),
    text("Enter confirms. Escape cancels.", style: theme.muted),
    gap: 1
  ),
  style: theme.border.border(:rounded).padding(1, 2).width(42)
)
%><%= Charming::Presentation::UI.center(dialog, width: screen.width, height: screen.height) %>
```

## Fixed Placement

Use `Charming::Presentation::UI.place` when the final output must fill the terminal:

```erb
<%
body = column(header, content, footer, gap: 1)
%><%= Charming::Presentation::UI.place(body, width: screen.width, height: screen.height, top: 0, left: 0) %>
```

`top:` and `left:` accept integers or `:center`.

## Modal Overlays

Use `Charming::Presentation::UI.overlay` to draw a modal, palette, tooltip, or toast over an existing frame:

```erb
<%
body = Charming::Presentation::UI.place(frame, width: screen.width, height: screen.height)

if palette
  modal = render_component Charming::Presentation::Components::Modal.new(
    title: "Command palette",
    content: palette,
    help: "Type to filter. Enter selects. Escape closes.",
    width: 52,
    theme: theme
  )
  body = Charming::Presentation::UI.overlay(body, modal)
end
%><%= body %>
```

## Dashboard Grids

Compose rows and columns recursively:

```erb
<%
metric = ->(label, value) do
  box(
    column(
      text(label, style: theme.muted),
      text(value, style: theme.title),
      gap: 1
    ),
    style: theme.border.border(:rounded).padding(1, 2).width(20)
  )
end
%><%= column(
  row(metric.call("Users", "12k"), metric.call("Revenue", "$8.4k"), gap: 2),
  row(activity, alerts, gap: 2),
  gap: 1
) %>
```

## Style Chaining

`Charming::Presentation::UI::Style` objects are immutable and chainable:

```erb
<%
panel_style = Charming::Presentation::UI.style
  .foreground(:bright_cyan)
  .background("#101820")
  .bold
  .border(:rounded, foreground: :bright_magenta)
  .padding(1, 2)
  .width(40)
  .align(:center)
%><%= box("System ready", style: panel_style) %>
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
