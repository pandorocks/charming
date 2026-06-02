# frozen_string_literal: true

module Charming
  module Generators
    # ControllerGenerator implements `charming generate controller NAME [ACTION ...]`.
    # Writes `app/controllers/<name>_controller.rb` containing a class that inherits
    # from the app's `ApplicationController` and a `show` (or named) action that renders
    # the conventional view with the command palette passed as an assign.
    class ControllerGenerator < AppFileGenerator
      # *name* is the resource name. *args* is the list of action names (defaults to `show`).
      # *out*, *destination*, and *force* are forwarded to the parent.
      def initialize(name, args, out:, destination:, force: false)
        super
        @actions = args
      end

      # Writes the controller file to the standard app/controllers path.
      def generate
        create_file(app_path("app", "controllers"), controller)
      end

      private

      # The list of action names supplied on the command line.
      attr_reader :actions

      # The file-name suffix used by `app_path` (sets "controller" so the file is
      # `<name>_controller.rb`).
      def suffix
        "controller"
      end

      # The full source of the generated controller file.
      def controller
        render_template("controller/controller.rb.template",
          app_class: app_name.class_name,
          controller_class: name.controller_class_name,
          action_methods: action_methods)
      end

      # Renders one action method per action name; falls back to a single `show` action
      # when no actions were specified.
      def action_methods
        return action_method("show") if actions.empty?

        actions.map { |action| action_method(action) }.join("\n")
      end

      # Source for a single action method that renders the matching conventional view and
      # passes the command palette as an assign.
      def action_method(action)
        "    def #{action}\n" \
          "      render :#{action}, palette: command_palette\n" \
          "    end\n"
      end
    end
  end
end
