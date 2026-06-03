# frozen_string_literal: true

require "fileutils"

module Charming
  module Generators
    # DatabaseInstaller implements `charming db:install sqlite3`. It adds database support
    # to an existing Charming app by creating `config/database.rb`, `app/models/application_record.rb`,
    # `db/migrate/`, and `db/seeds.rb`, and patching the gemspec and root loader to include
    # the new dependencies and the `app/models` autoload directory.
    class DatabaseInstaller
      # *database* is the adapter name (only "sqlite3" is currently supported). *out* is the
      # status-output stream. *destination* is the app root.
      def initialize(database, out:, destination:)
        @database = database
        @out = out
        @destination = destination
        @app_name = Name.new(app_name_from_gemspec)
      end

      # Performs the install: writes the database config, application record, migrate directory,
      # seeds file, and patches the gemspec + root loader. Idempotent: existing files are
      # reported with "exist <path>" instead of being overwritten.
      def install
        raise Error, "Unsupported database: #{database.inspect}" unless database == "sqlite3"

        create_file("config/database.rb", database_config)
        create_file("app/models/application_record.rb", application_record)
        create_file("db/migrate/.keep", "")
        create_file("db/seeds.rb", %(# frozen_string_literal: true
))
        update_gemspec
        update_root_file
      end

      private

      # The database adapter, status stream, app destination, and derived app name.
      attr_reader :database, :out, :destination, :app_name

      # Writes *content* to *path* (relative to the app root), creating intermediate directories.
      # Reports "exist <path>" without overwriting when the file already exists.
      def create_file(path, content)
        absolute_path = File.join(destination, path)
        if File.exist?(absolute_path)
          out.puts "exist #{path}"
          return
        end

        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, content)
        out.puts "create #{path}"
      end

      # Patches the gemspec to include the `db` directory in the gem files glob and to add
      # activerecord + sqlite3 dependencies.
      def update_gemspec
        update_file(gemspec_path) do |current|
          updated = current.sub('Dir.glob("{app,config,exe,lib}/**/*")', 'Dir.glob("{app,config,db,exe,lib}/**/*")')
          updated = insert_dependency(updated, "activerecord", "~> 8.1")
          insert_dependency(updated, "sqlite3", "~> 2.0")
        end
      end

      # Patches the root loader file (`lib/<app>.rb`) to require `config/database` and to push
      # the `app/models` autoload directory. Both edits are no-ops when already applied.
      def update_root_file
        update_file(root_file_path) do |current|
          updated = current
          updated = updated.sub(%(require "zeitwerk"\n), %(require "zeitwerk"\nrequire_relative "../config/database"\n)) unless updated.include?(%(require_relative "../config/database"))
          unless updated.include?(%[loader.push_dir(File.expand_path("../app/models", __dir__), namespace: #{app_name.class_name})])
            updated = updated.sub(
              %[loader.push_dir(File.expand_path("../app/state", __dir__), namespace: #{app_name.class_name})\n],
              %[loader.push_dir(File.expand_path("../app/models", __dir__), namespace: #{app_name.class_name})\nloader.push_dir(File.expand_path("../app/state", __dir__), namespace: #{app_name.class_name})\n]
            )
          end
          updated
        end
      end

      # Reads *path*, yields its contents to the block, and writes the result back when it
      # differs. Raises Error when the file is missing.
      def update_file(path)
        raise Error, "Missing file: #{relative_path(path)}" unless File.exist?(path)

        current = File.read(path)
        updated = yield current
        return if updated == current

        File.write(path, updated)
        out.puts "update #{relative_path(path)}"
      end

      # Inserts a `spec.add_dependency "name", "version"` line after the `charming` dependency
      # when it's not already present.
      def insert_dependency(content, gem_name, version)
        return content if content.include?(%(spec.add_dependency "#{gem_name}"))

        dependency = %(  spec.add_dependency "#{gem_name}", "#{version}")
        content.sub(%(  spec.add_dependency "charming"\n), %(  spec.add_dependency "charming"\n#{dependency}\n))
      end

      # The contents of the new `config/database.rb` (establishes an SQLite connection to
      # `db/development.sqlite3`).
      def database_config
        %(# frozen_string_literal: true

require "active_record"
require "fileutils"

database_path = File.expand_path("../db/development.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(database_path))

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: database_path
)
)
      end

      # The contents of the new `app/models/application_record.rb` (abstract ActiveRecord base).
      def application_record
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
)
      end

      # Reads the app's gemspec filename to derive the app name.
      def app_name_from_gemspec
        File.basename(gemspec_path, ".gemspec")
      end

      # The path to the app's gemspec (raises when not found).
      def gemspec_path
        @gemspec_path ||= Dir.glob(File.join(destination, "*.gemspec")).first || raise(Error, "Run this command from a Charming app root")
      end

      # The path to the app's root loader file (`lib/<app_name>.rb`).
      def root_file_path
        File.join(destination, "lib", "#{app_name.snake_name}.rb")
      end

      # Strips the app destination prefix from *path* for human-friendly status output.
      def relative_path(path)
        path.delete_prefix("#{destination}/")
      end
    end
  end
end
