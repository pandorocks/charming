# frozen_string_literal: true

module Charming
  module Generators
    # ScreenGenerator implements `charming generate screen NAME`. Writes a complete vertical
    # slice for a new screen: a state class, a controller with a `show` action, a view,
    # matching spec files, and inserts a route into `config/routes.rb` and a command entry
    # into `ApplicationController` for the command palette.
    class ScreenGenerator < AppFileGenerator
      include AppGenerator::ScreenSpecTemplates

      # *name* is the resource name. *args* is unused (raises Error when non-empty).
      def initialize(name, args, out:, destination:, force: false)
        super
        raise Error, "Usage: charming generate screen NAME" if args.any?
      end

      # Writes the state, controller, view, and three spec files, then inserts a route
      # and a command-palette entry.
      def generate
        create_file(state_path, state)
        create_file(controller_path, controller)
        create_file(view_path, view)
        create_file(spec_state_path, spec_state)
        create_file(spec_controller_path, spec_controller)
        create_file(spec_view_path, spec_view)
        insert_route
        insert_command
      end

      private

      # The file-name suffix used by `app_path` ("screen" — only used by the parent class).
      def suffix
        "screen"
      end

      # Path to the generated state class.
      def state_path
        File.join("app", "state", "#{name.snake_name}_state.rb")
      end

      # Path to the generated controller class.
      def controller_path
        File.join("app", "controllers", "#{name.snake_name}_controller.rb")
      end

      # Path to the generated `show` view.
      def view_path
        File.join("app", "views", name.snake_name, "show_view.rb")
      end

      # Path to the generated state spec.
      def spec_state_path
        File.join("spec", "state", "#{name.snake_name}_state_spec.rb")
      end

      # Path to the generated controller spec.
      def spec_controller_path
        File.join("spec", "controllers", "#{name.snake_name}_controller_spec.rb")
      end

      # Path to the generated view spec.
      def spec_view_path
        File.join("spec", "views", name.snake_name, "show_view_spec.rb")
      end

      # Absolute path to the app's `config/routes.rb`.
      def route_path
        File.join(destination, "config", "routes.rb")
      end

      # Absolute path to the app's `ApplicationController`.
      def application_controller_path
        File.join(destination, "app", "controllers", "application_controller.rb")
      end

      # The source of the generated state class.
      def state
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.class_name}State < ApplicationState
    attribute :title, :string, default: "#{name.class_name}"
  end
end
)
      end

      # The source of the generated controller class.
      def controller
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.controller_class_name} < ApplicationController
#{controller_body}
  end
end
)
      end

      # The body of the controller: a `show` action and a private accessor for the state.
      def controller_body
        %(    def show
      render :show,
        #{name.snake_name}: #{name.snake_name},
        palette: command_palette
    end

    private

    def #{name.snake_name}
      state(:#{name.snake_name}, #{name.class_name}State)
    end)
      end

      # The source of the generated view class.
      def view
        %(# frozen_string_literal: true

module #{app_name.class_name}
  module #{name.class_name}
    class ShowView < Charming::Presentation::View
      def render
        #{name.snake_name}.title
      end
    end
  end
end
)
      end

      # Inserts a `screen` route into `config/routes.rb`, idempotently.
      def insert_route
        route = %(  screen "/#{name.snake_name}", to: "#{name.snake_name}#show", title: "#{name.class_name}")
        insert_before_end(route_path, route, "route", "end")
      end

      # Inserts a `command` block into `ApplicationController`, idempotently.
      def insert_command
        command = %(    command "#{name.class_name}" do
      navigate_to "/#{name.snake_name}"
    end)
        insert_before_end(application_controller_path, command, "command", "  end")
      end

      # Inserts *content* into *path* just before the line matching *end_line*. No-ops when
      # the content is already present. Raises Error when the file or end-line is missing.
      def insert_before_end(path, content, label, end_line)
        raise Error, "Missing file: #{relative_path(path)}" unless File.exist?(path)

        current = File.read(path)
        return if current.include?(content)

        lines = current.lines
        index = insertion_index(lines, path, end_line)
        lines.insert(index, "#{content}\n")
        File.write(path, lines.join)
        out.puts "insert #{label} #{relative_path(path)}"
      end

      # Returns the index of the last line in *lines* that matches *end_line* (the line
      # just before which new content will be inserted). Raises Error when not found.
      def insertion_index(lines, path, end_line)
        index = lines.rindex { |line| line.chomp == end_line }
        raise Error, "Could not update #{relative_path(path)}" unless index

        index
      end

      # Strips the destination prefix from *path* for human-friendly status output.
      def relative_path(path)
        path.delete_prefix("#{destination}/")
      end
    end
  end
end
