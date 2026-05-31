# frozen_string_literal: true

module Charming
  module Generators
    class ScreenGenerator < AppFileGenerator
      include AppGenerator::ScreenSpecTemplates

      def initialize(name, args, out:, destination:, force: false)
        super
        raise Error, "Usage: charming generate screen NAME" if args.any?
      end

      def generate
        create_file(model_path, model)
        create_file(controller_path, controller)
        create_file(view_path, view)
        create_file(spec_model_path, spec_model)
        create_file(spec_controller_path, spec_controller)
        create_file(spec_view_path, spec_view)
        insert_route
        insert_command
      end

      private

      def suffix
        "screen"
      end

      def model_path
        File.join("app", "models", "#{name.snake_name}_model.rb")
      end

      def controller_path
        File.join("app", "controllers", "#{name.snake_name}_controller.rb")
      end

      def view_path
        File.join("app", "views", name.snake_name, "show.tui.erb")
      end

      def spec_model_path
        File.join("spec", "models", "#{name.snake_name}_model_spec.rb")
      end

      def spec_controller_path
        File.join("spec", "controllers", "#{name.snake_name}_controller_spec.rb")
      end

      def spec_view_path
        File.join("spec", "views", name.snake_name, "show_template_spec.rb")
      end

      def route_path
        File.join(destination, "config", "routes.rb")
      end

      def application_controller_path
        File.join(destination, "app", "controllers", "application_controller.rb")
      end

      def model
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.class_name}Model < ApplicationModel
    attribute :title, :string, default: "#{name.class_name}"
  end
end
)
      end

      def controller
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.controller_class_name} < ApplicationController
#{controller_body}
  end
end
)
      end

      def controller_body
        %(    def show
      render :show,
        #{name.snake_name}: #{name.snake_name},
        palette: command_palette
    end

    private

    def #{name.snake_name}
      model(:#{name.snake_name}, #{name.class_name}Model)
    end)
      end

      def view
        %(<%= #{name.snake_name}.title %>
)
      end

      def insert_route
        route = %(  screen "/#{name.snake_name}", to: "#{name.snake_name}#show", title: "#{name.class_name}")
        insert_before_end(route_path, route, "route", "end")
      end

      def insert_command
        command = %(    command "#{name.class_name}" do
      navigate_to "/#{name.snake_name}"
    end)
        insert_before_end(application_controller_path, command, "command", "  end")
      end

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

      def insertion_index(lines, path, end_line)
        index = lines.rindex { |line| line.chomp == end_line }
        raise Error, "Could not update #{relative_path(path)}" unless index

        index
      end

      def relative_path(path)
        path.delete_prefix("#{destination}/")
      end
    end
  end
end
