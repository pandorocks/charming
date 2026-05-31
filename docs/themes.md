# Themes

Themes provide semantic style tokens for templates, views, components, and layouts. Use theme tokens instead of hardcoded colors whenever possible.

## Register Built-In Themes

Generated apps register all built-in themes and choose `:phosphor` by default:

```ruby
class MyApp::Application < Charming::Application
  Charming::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor
end
```

## Register Custom Themes

Register a custom JSON theme file with `from:`:

```ruby
class MyApp::Application < Charming::Application
  theme :custom, from: "config/themes/custom.json"
  default_theme :custom
end
```

Relative paths resolve from `Application.root` when set, otherwise from the current working directory.

## Use Theme Tokens

Theme tokens return `Charming::UI::Style` objects:

```ruby
text "Welcome", style: theme.title
text "Status", style: theme.muted
text "Alert", style: theme.info
```

Default tokens:

| Token | Meaning |
|-------|---------|
| `text` | Primary text |
| `title` | Bright title text |
| `muted` | Secondary text |
| `border` | Border styling |
| `selected` | Selected/focused item styling |
| `info` | Informational accent |
| `warn` | Warning accent |

Tokens are style objects, so they can be chained:

```ruby
theme.title.align(:center).width(40)
theme.border.border(:rounded).padding(1, 2)
```

## Runtime Theme Switching

Switch themes from a controller with:

```ruby
use_theme :phosphor
```

Generated apps expose a theme picker command:

```ruby
command "Theme", :open_theme_palette
```

`open_theme_palette` opens a command-palette-like list of registered themes.

## Theme JSON Shape

Theme JSON files contain a `styles` object and may contain a `palette` and `background`:

```json
{
  "palette": {
    "cyan": "#00ffff"
  },
  "background": "#101820",
  "styles": {
    "title": { "foreground": "cyan", "bold": true },
    "muted": { "foreground": "#777777" },
    "border": { "foreground": "cyan" }
  }
}
```

Style options mirror `Charming::UI::Style` methods: foreground/background colors, text attributes, padding, border, width, height, and alignment.
