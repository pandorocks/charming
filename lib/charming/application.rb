# frozen_string_literal: true

module Charming
  # Application is a lightweight, Rails-inspired application base for building
  # terminal-based apps. It provides routing (via a DSL), session storage, and
  # task execution for managing async operations.
  class Application
    THEME_READER = Object.new.freeze

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

      def root(path = THEME_READER)
        return @root if path == THEME_READER

        @root = File.expand_path(path)
      end

      def theme(name, from: nil, built_in: nil)
        raise ArgumentError, "theme expects from: or built_in:" unless from || built_in
        raise ArgumentError, "theme expects either from: or built_in:, not both" if from && built_in

        themes[name.to_sym] = if built_in
          Presentation::UI::Theme.load_builtin(built_in)
        else
          Presentation::UI::Theme.load_file(resolve_theme_path(from))
        end
      end

      def themes
        @themes ||= superclass.respond_to?(:themes) ? superclass.themes.dup : {}
      end

      def default_theme(name = THEME_READER)
        return @default_theme || themes.keys.first if name == THEME_READER

        @default_theme = name.to_sym
      end

      def theme_for(name = nil)
        theme_name = name || default_theme
        return Presentation::UI::Theme.default unless theme_name

        themes.fetch(theme_name.to_sym)
      end

      private

      def resolve_theme_path(path)
        return path if File.absolute_path?(path)

        File.expand_path(path, root || Dir.pwd)
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

    def theme
      self.class.theme_for(session[:theme])
    end

    def use_theme(name)
      self.class.theme_for(name)
      session[:theme] = name.to_sym
    end
  end
end
