# frozen_string_literal: true

module Charming
  module Generators
    class ControllerGenerator < AppFileGenerator
      def initialize(name, args, out:, destination:, force: false)
        super
        @actions = args
      end

      def generate
        create_file(app_path("app", "controllers"), controller)
      end

      private

      attr_reader :actions

      def suffix
        "controller"
      end

      def controller
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.controller_class_name} < ApplicationController
#{action_methods}  end
end
)
      end

      def action_methods
        return action_method("show") if actions.empty?

        actions.map { |action| action_method(action) }.join("\n")
      end

      def action_method(action)
        %(    def #{action}
      render :#{action}, palette: command_palette
    end
)
      end
    end
  end
end
