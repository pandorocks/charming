# frozen_string_literal: true

module Charming
  module Generators
    class ViewGenerator < AppFileGenerator
      def initialize(name, args, out:, destination:, force: false)
        super
        raise Error, "Usage: charming generate view NAME [ACTION]" if args.length > 1

        @action = args.fetch(0, "show")
      end

      def generate
        create_file(File.join("app", "views", name.snake_name, "#{action}_view.rb"), view)
      end

      private

      attr_reader :action

      def suffix
        "view"
      end

      def view
        %(# frozen_string_literal: true

module #{app_name.class_name}
  module #{name.class_name}
    class #{action_class_name}View < Charming::Presentation::View
      def render
        "#{name.class_name}"
      end
    end
  end
end
)
      end

      def action_class_name
        action.split("_").map(&:capitalize).join
      end
    end
  end
end
