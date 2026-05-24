# frozen_string_literal: true

require_relative "app_file_generator"

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
