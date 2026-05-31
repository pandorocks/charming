# Getting Started

This guide walks through a generated Charming app. For deeper explanations, use the topic docs linked throughout this page.

## Install Charming

Install the CLI gem on your machine:

```sh
gem install charming
```

Generate and run an app:

```sh
charming new my_app
cd my_app
bundle install
bundle exec exe/my_app
```

## Generated Files

Generated apps use Rails-like folders:

```text
app/components/
app/controllers/
app/state/
app/views/home/show.tui.erb
app/views/layouts/application.tui.erb
config/routes.rb
exe/my_app
lib/my_app.rb
lib/my_app/application.rb
spec/
```

The executable boots the app with:

```ruby
Charming.run(MyApp::Application.new)
```

The generated app flow is:

```text
Route -> Controller Action -> Template -> Layout -> Renderer -> Terminal
```

Read more in [Core Concepts](core_concepts.md).

## Routes

Routes live in `config/routes.rb`:

```ruby
MyApp::Application.routes do
  root "home#show"
  screen "/cities/:id", to: "cities#show", title: "City"
end
```

`root` maps `/` to a controller action. `screen` maps a path to `controller#action`. Dynamic route segments are available through `params`.

Read more in [Routing](routing.md).

## Controllers And Templates

Generated controllers render templates by symbol:

```ruby
module MyApp
  class HomeController < ApplicationController
    key "p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global

    def show
      render :show, home: home, palette: command_palette
    end

    private

    def home
      state(:home, HomeState)
    end
  end
end
```

For `HomeController`, `render :show` resolves:

```text
app/views/home/show.tui.erb
```

Templates are ERB files with access to assigns and view helpers:

```erb
<%= text home.title, style: theme.title %>
<%= text "Press p for commands, q to quit.", style: theme.muted %>
```

Read more in [Controllers & Templates](controllers_and_templates.md).

## Layouts

Generated apps use a template layout:

```ruby
module MyApp
  class ApplicationController < Charming::Controller
    layout "layouts/application"
    focus_ring :sidebar, :content
  end
end
```

That resolves:

```text
app/views/layouts/application.tui.erb
```

Layouts use `yield_content` to place the current screen inside shared UI:

```erb
<%
sidebar = box("Home\nSettings", style: theme.border.border(:rounded).padding(1, 2).width(20))
main = box(yield_content, style: theme.border.border(:rounded).padding(1, 2).width(60))
frame = row(sidebar, main, gap: 1)
%><%= Charming::Presentation::UI.place(frame, width: screen.width, height: screen.height) %>
```

Read more in [Layouts](layouts.md).

## State

State classes store durable in-memory TUI state:

```ruby
module MyApp
  class HomeState < ApplicationState
    attribute :title, :string, default: "Home"
    attribute :count, :integer, default: 0
  end
end
```

Controllers are ephemeral, so use `state(:home, HomeState)` for state that must survive dispatches.

Read more in [State](state.md).

## Components

Render components from templates with `render_component`:

```erb
<%= render_component AppFrameComponent.new(title: home.title, theme: theme) %>
```

Components can be static renderable objects or interactive widgets that implement `handle_key(event)` and `handle_mouse(event)`.

Read more in [Components](components.md).

## Themes

Generated apps register built-in themes and default to `:phosphor`:

```ruby
class MyApp::Application < Charming::Application
  Charming::Presentation::UI::Theme.built_in_names.each do |theme_name|
    theme theme_name.to_sym, built_in: theme_name
  end

  default_theme :phosphor
end
```

Templates and components should use semantic tokens:

```ruby
text "Title", style: theme.title
text "Help", style: theme.muted
```

Read more in [Themes](themes.md).

## Generate More Files

Inside an app:

```sh
charming generate screen forecast
charming generate controller forecast show
charming generate view forecast show
charming generate component forecast_card
```

`generate` can be shortened to `g`.

## Run Tests

Generated apps include RSpec specs. Run them with:

```sh
bundle exec rspec
```

For controller, template, component, timer, task, and runtime testing patterns, see [Testing](testing.md).
