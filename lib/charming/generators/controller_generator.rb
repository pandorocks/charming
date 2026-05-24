# frozen_string_literal: true

require_relative "app_file_generator"

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
  class #{name.controller_class_name} < Charming::Controller
#{action_methods}  end
end
)
      end

      def action_methods
        return "    def show\n      render \"#{name.class_name}#show\"\n    end\n" if actions.empty?

        actions.map { |action| action_method(action) }.join("\n")
      end

      def action_method(action)
        "    def #{action}\n      render \"#{name.class_name}##{action}\"\n    end\n"
      end
    end
  end
end
