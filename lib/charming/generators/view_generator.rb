# frozen_string_literal: true

module Charming
  module Generators
    # ViewGenerator implements `charming generate view NAME [ACTION]`. Writes a single
    # view class file at `app/views/<name>/<action>_view.rb`. The *action* defaults to `show`.
    class ViewGenerator < AppFileGenerator
      # *name* is the resource name. *args* may contain a single action name (defaults to "show").
      def initialize(name, args, out:, destination:, force: false)
        super
        raise Error, "Usage: charming generate view NAME [ACTION]" if args.length > 1

        @action = args.fetch(0, "show")
      end

      # Writes the view file to `app/views/<name>/<action>_view.rb`.
      def generate
        create_file(File.join("app", "views", name.snake_name, "#{action}_view.rb"), view)
      end

      private

      # The action name (e.g., "show", "edit").
      attr_reader :action

      # The file-name suffix used by `app_path` (sets "view" so the file is
      # `<name>_view.rb`). Not used directly by this generator but required by the parent.
      def suffix
        "view"
      end

      # The full source of the generated view class.
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

      # CamelCase rendering of the action name (e.g., "user_settings" → "UserSettings").
      def action_class_name
        action.split("_").map(&:capitalize).join
      end
    end
  end
end
