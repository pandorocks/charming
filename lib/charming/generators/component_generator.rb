# frozen_string_literal: true

require_relative "app_file_generator"

module Charming
  module Generators
    class ComponentGenerator < AppFileGenerator
      def generate
        create_file(app_path("app", "components"), component)
      end

      private

      def suffix
        "component"
      end

      def component
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.component_class_name} < Charming::Component
    def render
      text "#{name.class_name}"
    end
  end
end
)
      end
    end
  end
end
