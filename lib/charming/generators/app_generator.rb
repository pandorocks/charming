# frozen_string_literal: true

require_relative "base"
require_relative "name"
require_relative "app_generator/basic_templates"
require_relative "app_generator/component_templates"
require_relative "app_generator/controller_template"
require_relative "app_generator/layout_template"
require_relative "app_generator/model_templates"
require_relative "app_generator/view_template"

module Charming
  module Generators
    class AppGenerator < Base
      include AppGeneratorTemplates::BasicTemplates
      include AppGeneratorTemplates::ComponentTemplates
      include AppGeneratorTemplates::ControllerTemplate
      include AppGeneratorTemplates::LayoutTemplate
      include AppGeneratorTemplates::ModelTemplates
      include AppGeneratorTemplates::ViewTemplate

      FILE_TEMPLATES = [
        ["Gemfile", :gemfile],
        ["Rakefile", :rakefile],
        ["README.md", :readme],
        ["%<name>s.gemspec", :gemspec],
        ["exe/%<name>s", :executable],
        ["lib/%<name>s.rb", :root_file],
        ["lib/%<name>s/application.rb", :application],
        ["lib/%<name>s/version.rb", :version],
        ["config/routes.rb", :routes],
        ["app/models/application_model.rb", :application_model],
        ["app/models/home_model.rb", :home_model],
        ["app/controllers/application_controller.rb", :application_controller],
        ["app/controllers/home_controller.rb", :controller],
        ["app/views/layouts/application.rb", :layout],
        ["app/views/home_view.rb", :view],
        ["app/components/app_frame_component.rb", :component],
        ["spec/spec_helper.rb", :spec_helper]
      ].freeze

      def initialize(name, out:, destination:, force: false)
        super(out: out, destination: File.join(destination, name), force: force)
        @name = Name.new(name)
      end

      def generate
        FILE_TEMPLATES.each do |path, template|
          create_file(file_path(path), send(template), executable: template == :executable)
        end
      end

      private

      attr_reader :name

      def file_path(path)
        format(path, name: name.snake_name)
      end

      def routes
        %(# frozen_string_literal: true

#{name.class_name}::Application.routes do
  root "home#show"
end
)
      end

      def spec_helper
        %(# frozen_string_literal: true

require "#{name.snake_name}"
)
      end
    end
  end
end
