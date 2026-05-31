# Routing

Generated apps define routes in `config/routes.rb` by calling `routes` on the application class.

```ruby
MyApp::Application.routes do
  root "home#show"
  screen "/cities", to: "cities#index", title: "Cities"
  screen "/cities/:id", to: "cities#show", title: "City"
end
```

## Route DSL

| Method | Purpose |
|--------|---------|
| `root "home#show"` | Maps `/` to `HomeController#show`. |
| `screen "/path", to: "controller#action"` | Maps a path to a controller action. |
| `title:` | Sets a display title used by generated sidebar layouts. |

Controller names are resolved inside the application namespace. In a generated `MyApp` app, `to: "home#show"` resolves to `MyApp::HomeController`.

## Dynamic Params

Dynamic segments use `:name` and match one path segment:

```ruby
screen "/cities/:id", to: "cities#show"
```

Controller actions access dynamic params through `params`:

```ruby
module MyApp
  class CitiesController < ApplicationController
    def show
      render "City #{params[:id]}"
    end
  end
end
```

Params are symbol-keyed and URL-decoded.

## Resolution Rules

- Exact routes win over dynamic routes.
- Dynamic params match one segment.
- Missing routes raise `KeyError`.
- `application.routes.all` returns routes in insertion order.

Generated layouts use `application.routes.all` to build sidebar navigation.

## Route Titles

When no `title:` is supplied, Charming derives one from the path:

```ruby
screen "/project_settings", to: "settings#show"
# title: "Project Settings"
```

Use explicit titles for sidebar labels that should differ from the path.

## Generating Screens

Inside a generated app, create a screen with:

```sh
charming generate screen forecast
```

That creates a model, controller, template, specs, inserts a route, and inserts a command palette entry.
