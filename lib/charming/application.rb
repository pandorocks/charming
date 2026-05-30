# frozen_string_literal: true

module Charming
  # Application is a lightweight, Rails-inspired application base for building
  # terminal-based apps. It provides routing (via a DSL), session storage, and
  # task execution for managing async operations.
  class Application
    class << self
      # Registers or returns the app's Router. Accepts an optional block to define
      # routes via DSL (screen, root). Lazily initializes a new Router per namespace.
      def routes(&block)
        @routes ||= Router.new(namespace: namespace)
        @routes.draw(&block) if block
        @routes
      end

      # Derives the module namespace from the class name — e.g., Admin::HomeController
      # yields "Admin". Mirrors Rails' engine-style namespacing.
      def namespace
        name&.split("::")&.then { |parts| parts[0...-1].join("::") }
      end
    end

    attr_accessor :task_executor
    attr_reader :session

    # Initializes an empty session hash for per-request state storage.
    def initialize
      @session = {}
    end

    # Delegates to the class-level Router, providing instance access to route definitions.
    def routes
      self.class.routes
    end
  end
end
