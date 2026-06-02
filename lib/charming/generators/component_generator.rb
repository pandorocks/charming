# frozen_string_literal: true

module Charming
  module Generators
    # ComponentGenerator implements `charming generate component NAME`. Writes a
    # `Charming::Presentation::Component` subclass to `app/components/<name>_component.rb`.
    class ComponentGenerator < AppFileGenerator
      # Writes the component file to the standard `app/components` path.
      def generate
        create_file(app_path("app", "components"), component)
      end

      private

      # The file-name suffix used by `app_path` (sets "component" so the file is
      # `<name>_component.rb`).
      def suffix
        "component"
      end

      # The full source of the generated component class.
      def component
        render_template("component/component.rb.template",
          app_class: app_name.class_name,
          component_class: name.component_class_name,
          resource_name: name.class_name)
      end
    end
  end
end
