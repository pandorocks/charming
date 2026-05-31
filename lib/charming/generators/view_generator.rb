# frozen_string_literal: true

module Charming
  module Generators
    class ViewGenerator < AppFileGenerator
      def generate
        create_file(app_path("app", "views"), view)
      end

      private

      def suffix
        "view"
      end

      def view
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.view_class_name} < Charming::View
#{view_body}
  end
end
)
      end

      def view_body
        %(    def render
      "#{name.class_name}"
    end)
      end
    end
  end
end
