# frozen_string_literal: true

module Charming
  module Generators
    # AppGenerator implements `charming new NAME`. Writes a complete Bundler-gem-style
    # Charming app skeleton: Gemfile, Rakefile, gemspec, exe, lib root + application +
    # version, config/routes.rb, app/state, app/controllers, app/views/layouts + home view,
    # and a baseline spec/ tree. Optionally also creates the database files when
    # `database:` is set.
    class AppGenerator < Base
      include BasicTemplates
      include ControllerTemplate
      include DatabaseTemplates
      include LayoutTemplate
      include StateTemplates
      include ScreenSpecTemplates
      include ViewTemplate
      include AppSpecTemplates

      # The list of [relative-path, template-method] pairs to render for a non-database app.
      BASE_FILE_TEMPLATES = [
        ["Gemfile", :gemfile],
        ["Rakefile", :rakefile],
        ["README.md", :readme],
        ["%<name>s.gemspec", :gemspec],
        ["exe/%<name>s", :executable],
        ["lib/%<name>s.rb", :root_file],
        ["lib/%<name>s/application.rb", :application],
        ["lib/%<name>s/version.rb", :version],
        ["config/routes.rb", :routes],
        ["app/state/application_state.rb", :application_state],
        ["app/state/home_state.rb", :home_state],
        ["app/controllers/application_controller.rb", :application_controller],
        ["app/controllers/home_controller.rb", :controller],
        ["app/views/layouts/application_layout.rb", :layout],
        ["app/views/home/show_view.rb", :view],
        ["app/components/.keep", :keep],
        ["spec/spec_helper.rb", :spec_helper],
        ["spec/state/home_state_spec.rb", :spec_state],
        ["spec/controllers/home_controller_spec.rb", :spec_controller],
        ["spec/views/home/show_view_spec.rb", :spec_view]
      ].freeze

      # The list of [relative-path, template-method] pairs to render in addition to the
      # base list when `database:` is set on the generator.
      DATABASE_FILE_TEMPLATES = [
        ["config/database.rb", :database_config],
        ["app/models/application_record.rb", :application_record],
        ["db/migrate/.keep", :keep],
        ["db/seeds.rb", :seeds]
      ].freeze

      # *name* is the new app's name. *out* is the status stream. *destination* is the
      # parent directory under which `<name>/` will be created. *force* allows overwriting
      # existing files. *database* optionally enables the database template set.
      def initialize(name, out:, destination:, force: false, database: nil)
        super(out: out, destination: File.join(destination, name), force: force)
        @name = Name.new(name)
        @database = database
      end

      # Renders every template in the chosen template list (base + optional database)
      # and writes the files, then initializes a git repository in the new app directory.
      def generate
        file_templates.each do |path, template|
          create_file(file_path(path), send(template), executable: template == :executable)
        end
        initialize_git_repository
      end

      private

      # The resource name and the database adapter name (or nil).
      attr_reader :name, :database
      alias_method :app_name, :name

      # True when the database template set should be rendered.
      def database?
        !!database
      end

      # Returns the template list: base only, or base + database extras.
      def file_templates
        database? ? BASE_FILE_TEMPLATES + DATABASE_FILE_TEMPLATES : BASE_FILE_TEMPLATES
      end

      # Substitutes `name.snake_name` into a relative-path template (paths use `%<name>s`).
      def file_path(path)
        format(path, name: name.snake_name)
      end

      # The `config/routes.rb` content: a single root route pointing at the home controller.
      def routes
        %(# frozen_string_literal: true

#{name.class_name}::Application.routes do
  root "home#show"
end
)
      end

      # The `spec/spec_helper.rb` content: requires the app's root file so RSpec can boot.
      def spec_helper
        %(# frozen_string_literal: true

require "#{name.snake_name}"
)
      end

      # Initializes a git repository in the new app's directory. Raises Error on failure.
      def initialize_git_repository
        unless system("git", "init", chdir: destination, out: File::NULL, err: File::NULL)
          raise Error, "Could not initialize git repository"
        end

        out.puts "init git"
      end
    end
  end
end
