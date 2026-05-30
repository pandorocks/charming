# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator < Base
      include BasicTemplates
      include ComponentTemplates
      include ControllerTemplate
      include LayoutTemplate
      include ModelTemplates
      include ScreenSpecTemplates
      include ViewTemplate
      include AppSpecTemplates

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
        ["spec/spec_helper.rb", :spec_helper],
        ["spec/models/home_model_spec.rb", :spec_model],
        ["spec/controllers/home_controller_spec.rb", :spec_controller],
        ["spec/views/home_view_spec.rb", :spec_view],
        ["spec/components/app_frame_component_spec.rb", :spec_component]
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
      alias_method :app_name, :name

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
