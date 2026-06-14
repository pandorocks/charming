# frozen_string_literal: true

module Charming
  module Generators
    # AppGenerator implements `charming new NAME`. Writes a complete Bundler-gem-style
    # Charming app skeleton: Gemfile, Rakefile, gemspec, exe, lib root + application +
    # version, config/routes.rb, app/state, app/controllers, app/views/layouts + home view,
    # and a baseline spec/ tree. Optionally also creates the database files when
    # `database:` is set.
    class AppGenerator < Base
      # The list of [relative-path, template-path, executable-flag] triples to render
      # for a non-database app.
      BASE_FILE_TEMPLATES = [
        ["Gemfile", "app/Gemfile.template", false],
        ["Rakefile", "app/Rakefile.template", false],
        [".rspec", "app/dot_rspec.template", false],
        ["README.md", "app/README.md.template", false],
        ["%<name>s.gemspec", "app/gemspec.template", false],
        ["exe/%<name>s", "app/executable.template", true],
        ["lib/%<name>s.rb", "app/root_file.template", false],
        ["lib/%<name>s/application.rb", "app/application.template", false],
        ["lib/%<name>s/version.rb", "app/version.template", false],
        ["config/routes.rb", "app/routes.template", false],
        ["app/state/application_state.rb", "app/application_state.template", false],
        ["app/state/home_state.rb", "app/home_state.template", false],
        ["app/controllers/application_controller.rb", "app/application_controller.template", false],
        ["app/controllers/home_controller.rb", "app/home_controller.template", false],
        ["app/views/layouts/application_layout.rb", "app/layout.template", false],
        ["app/views/home/show_view.rb", "app/view.template", false],
        ["app/components/.keep", "app/keep.template", false],
        ["spec/spec_helper.rb", "app/spec_helper.template", false],
        ["spec/state/home_state_spec.rb", "app/spec_state.template", false],
        ["spec/controllers/home_controller_spec.rb", "app/spec_controller.template", false],
        ["spec/views/home/show_view_spec.rb", "app/spec_view.template", false]
      ].freeze

      # The list of [relative-path, template-path, executable-flag] triples to render in
      # addition to the base list when `database:` is set on the generator.
      DATABASE_FILE_TEMPLATES = [
        ["config/database.rb", "app/database_config.template", false],
        ["app/models/application_record.rb", "app/application_record.template", false],
        ["db/migrate/.keep", "app/keep.template", false],
        ["db/seeds.rb", "app/seeds.template", false]
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
        file_templates.each do |path, template_path, executable|
          create_file(file_path(path), render_app_template(template_path), executable: executable)
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

      # Renders an app template file by replacing `__TOKEN__` placeholders with the
      # appropriate values derived from the current *name* and *database* setting.
      def render_app_template(relative_path)
        render_template(relative_path, **app_template_tokens)
      end

      # Returns the token map used to render every app template.
      def app_template_tokens
        {
          app_name: name.class_name,
          app_snake: name.snake_name,
          app_class: name.class_name,
          gemspec_attributes: gemspec_attributes,
          gemspec_dependencies: gemspec_dependencies,
          controller_actions: controller_actions,
          controller_helpers: controller_helpers,
          database_require: database_require,
          model_loader: model_loader,
          env_setup: env_setup,
          database_spec_setup: database_spec_setup
        }
      end

      # Pins CHARMING_ENV to "test" before the app (and its database config) loads, so
      # specs hit db/test.sqlite3. Empty for non-database apps.
      def env_setup
        return "" unless database?

        "ENV[\"CHARMING_ENV\"] ||= \"test\"\n\n"
      end

      # Prepares the test database schema before the suite and rolls back each example's
      # writes in a transaction. Empty for non-database apps.
      def database_spec_setup
        return "" unless database?

        <<~RUBY

          # Prepare the test database, preferring the dumped schema over replaying migrations.
          schema = File.expand_path("../db/schema.rb", __dir__)
          if File.exist?(schema)
            load schema
          else
            ActiveRecord::MigrationContext.new(File.expand_path("../db/migrate", __dir__)).migrate
          end

          RSpec.configure do |config|
            # Roll back database writes after each example so tests stay isolated.
            config.around(:each) do |example|
              ActiveRecord::Base.transaction(requires_new: true) do
                example.run
                raise ActiveRecord::Rollback
              end
            end
          end
        RUBY
      end

      # The `Gem::Specification` attributes block (indented two spaces to match the wrapping
      # `Gem::Specification.new do |spec|`).
      def gemspec_attributes
        "  spec.name = \"#{name.snake_name}\"\n" \
          "  spec.version = #{name.class_name}::VERSION\n" \
          "  spec.summary = \"A Charming terminal user interface.\"\n" \
          "  spec.authors = [\"TODO: Your name\"]\n" \
          "  spec.email = [\"TODO: Your email\"]\n" \
          "  spec.files = Dir.glob(\"#{gemspec_file_glob}/**/*\") + %w[README.md]\n" \
          "  spec.bindir = \"exe\"\n" \
          "  spec.executables = [\"#{name.snake_name}\"]\n" \
          "  spec.require_paths = [\"lib\"]\n" \
          "  spec.required_ruby_version = \">= 4.0.0\"\n" \
          "  spec.metadata[\"rubygems_mfa_required\"] = \"true\""
      end

      # The `Gem::Specification` `add_dependency` lines (trailing newline).
      def gemspec_dependencies
        "\n  spec.add_dependency \"charming\"#{database_dependencies}\n"
      end

      # The file glob used by the gemspec to enumerate packaged files.
      def gemspec_file_glob
        database? ? "{app,config,db,exe,lib}" : "{app,config,exe,lib}"
      end

      # The optional `activerecord`/`sqlite3` dependency lines (with leading newlines and
      # trailing newline) when the app is database-configured; otherwise an empty string.
      def database_dependencies
        return "" unless database?

        "\n  spec.add_dependency \"activerecord\", \"~> 8.1\"\n" \
          "  spec.add_dependency \"sqlite3\", \"~> 2.0\""
      end

      # The body of the home controller's `show` action.
      def controller_actions
        "\n    def show\n" \
          "      render :show, home: home, palette: command_palette\n" \
          "    end"
      end

      # The body of the home controller's private `home` helper, prefixed by a blank line.
      def controller_helpers
        "\n\n    private\n\n" \
          "    def home\n" \
          "      state(:home, HomeState)\n" \
          "    end\n"
      end

      # The `require_relative "../config/database"` line when the app is database-configured.
      def database_require
        database? ? "require_relative \"../config/database\"" : ""
      end

      # The model loader `push_dir` line (with trailing newline) when the app is
      # database-configured; otherwise an empty string.
      def model_loader
        return "" unless database?

        "loader.push_dir(File.expand_path(\"../app/models\", __dir__), namespace: #{name.class_name})\n"
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
