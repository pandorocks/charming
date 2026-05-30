# frozen_string_literal: true

module Charming
  # Router manages an application's route table and provides a Rails-inspired DSL for defining routes.
  # Each route maps a URL path to a controller, action (implicitly :show), and title (for sidebar display).
  class Router
    # Route is a Data object holding the four pieces of information for a single route: path, controller class, action symbol, and sidebar title.
    Route = Data.define(:path, :controller_class, :action, :title)

    # Initializes a new router with an optional namespace prefix for controller constant lookups.
    def initialize(namespace: nil)
      @namespace = namespace
      @routes = {}
    end

    # Evaluates a block in the context of this Router instance using instance_eval, allowing DSL calls like screen and root to register routes.
    # This is how `routes.draw { screen "/", to: "HomeController", title: "Home" }` works.
    def draw(&)
      instance_eval(&)
    end

    # Registers the home screen at "/" with a given title. Shorthand for `screen path, to: target`.
    # Example: `root "HomeController"` maps `/` → HomeController#show with title "Home".
    def root(target, title: "Home")
      screen("/", to: target, title: title)
    end

    # Maps a URL path to a controller and action (e.g. "HomeController" for HomeController#show).
    # Builds a Route object from the path, resolved controller constant, parsed action, and an optional or derived title.
    def screen(path, to:, title: nil)
      controller_name, action = to.split("#", 2)
      @routes[path] = Route.new(
        path: path,
        controller_class: constantize(controller_constant_name(controller_name)),
        action: action.to_sym,
        title: title || derive_title(path)
      )
    end

    # Resolves a route by path from the router's table. Raises KeyError if no route matches.
    # Used at runtime to look up the controller class and action for incoming requests.
    def resolve(path = "/")
      @routes.fetch(path)
    end

    # Returns all registered routes as Route objects, ordered by insertion.
    # Consumed by the application loop to populate the sidebar and by controllers for navigation context.
    def all
      @routes.values
    end

    private

    # The namespace prefix from initialization — used to scope controller constant lookups.
    # For example, namespace "Admin" means HomeController resolves as Admin::HomeController.
    attr_reader :namespace

    # Splits a camel-case string into words for title derivation (e.g., "my_route" → ["my", "route"]).
    def camelize(value)
      value.split("_").map(&:capitalize).join
    end

    # Looks up a constant by name in Object. Used to resolve controller strings from route definitions.
    def constantize(name)
      Object.const_get(name)
    end

    # Builds the full controller constant name, prepending the namespace if present.
    # For example: "HomeController" with namespace "Admin" → "Admin::HomeController".
    def controller_constant_name(controller_name)
      name = "#{camelize(controller_name)}Controller"
      @namespace.to_s.empty? ? name : "#{@namespace}::#{name}"
    end

    # Derives a human-readable title from a URL path by stripping the leading slash,
    # splitting on underscores/hyphens/slashes, capitalizing each segment, and joining with spaces.
    # Examples: "/projects" → "Projects", "/projects/list" → "Projects List".
    def derive_title(path)
      return "Home" if path == "/"

      path.delete_prefix("/").split(%r{[_\-/]}).map(&:capitalize).join(" ")
    end
  end
end
