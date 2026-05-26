# frozen_string_literal: true

module Charming
  class Router
    Route = Data.define(:path, :controller_class, :action, :title)

    def initialize(namespace: nil)
      @namespace = namespace
      @routes = {}
    end

    def draw(&)
      instance_eval(&)
    end

    def root(target, title: "Home")
      screen("/", to: target, title: title)
    end

    def screen(path, to:, title: nil)
      controller_name, action = to.split("#", 2)
      @routes[path] = Route.new(
        path: path,
        controller_class: constantize(controller_constant_name(controller_name)),
        action: action.to_sym,
        title: title || derive_title(path)
      )
    end

    def resolve(path = "/")
      @routes.fetch(path)
    end

    def all
      @routes.values
    end

    private

    attr_reader :namespace

    def camelize(value)
      value.split("_").map(&:capitalize).join
    end

    def constantize(name)
      Object.const_get(name)
    end

    def controller_constant_name(controller_name)
      name = "#{camelize(controller_name)}Controller"
      namespace.to_s.empty? ? name : "#{namespace}::#{name}"
    end

    def derive_title(path)
      return "Home" if path == "/"

      path.delete_prefix("/").split(%r{[_\-/]}).map(&:capitalize).join(" ")
    end
  end
end
