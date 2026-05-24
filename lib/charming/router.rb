# frozen_string_literal: true

module Charming
  class Router
    Route = Data.define(:path, :controller_class, :action)

    def initialize
      @routes = {}
    end

    def draw(&)
      instance_eval(&)
    end

    def root(target)
      screen("/", to: target)
    end

    def screen(path, to:)
      controller_name, action = to.split("#", 2)
      @routes[path] = Route.new(
        path: path,
        controller_class: constantize("#{camelize(controller_name)}Controller"),
        action: action.to_sym
      )
    end

    def resolve(path = "/")
      @routes.fetch(path)
    end

    private

    def camelize(value)
      value.split("_").map(&:capitalize).join
    end

    def constantize(name)
      Object.const_get(name)
    end
  end
end
