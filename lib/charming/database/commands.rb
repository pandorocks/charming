# frozen_string_literal: true

require "fileutils"

module Charming
  module Database
    # Commands implements the runtime side of `charming db:COMMAND` (other than
    # `db:install`, which lives in Generators::DatabaseInstaller). It loads the app's
    # `config/database.rb`, delegates the actual work to ActiveRecord, and prints a short
    # status line on success.
    #
    # Supported commands: db:create, db:migrate, db:rollback [STEP=n], db:drop, db:seed,
    # db:setup, db:reset, db:prepare, db:status, db:version, db:schema:dump, db:schema:load.
    # The target database file is selected by CHARMING_ENV (development, test, production).
    class Commands
      # *command* is the subcommand string (e.g., "db:create"). *args* holds extra CLI
      # arguments such as "STEP=2". *out* is the status-output stream. *destination* is the
      # app root for resolving `config/database.rb` and `db/`.
      def initialize(command, out:, destination:, args: [])
        @command = command
        @args = args
        @out = out
        @destination = destination
      end

      # Dispatches the configured command. Raises Generators::Error for unknown commands.
      def run
        case command
        when "db:create" then create
        when "db:migrate" then migrate
        when "db:rollback" then rollback
        when "db:drop" then drop
        when "db:seed" then seed
        when "db:setup" then setup
        when "db:reset" then reset
        when "db:prepare" then prepare
        when "db:status" then status
        when "db:version" then version
        when "db:schema:dump" then schema_dump
        when "db:schema:load" then schema_load
        else raise Generators::Error, "Unknown database command: #{command}"
        end
      end

      private

      # The subcommand, extra arguments, output stream, and app destination.
      attr_reader :command, :args, :out, :destination

      # Creates the SQLite database file (touch) and establishes the connection.
      def create
        load_database
        FileUtils.mkdir_p(File.dirname(database_path)) if database_path
        FileUtils.touch(database_path) if database_path
        ActiveRecord::Base.connection
        out.puts "create #{relative_database_path}"
      end

      # Runs all pending migrations from `db/migrate`, then refreshes `db/schema.rb`.
      def migrate
        load_database
        migration_context.migrate
        dump_schema
        out.puts "migrate db/migrate"
      end

      # Rolls back the most recent migration(s). Accepts `STEP=n` (default 1), then
      # refreshes `db/schema.rb`.
      def rollback
        load_database
        migration_context.rollback(step_argument)
        dump_schema
        out.puts "rollback db/migrate (#{step_argument} step#{"s" if step_argument > 1})"
      end

      # Disconnects ActiveRecord, then deletes the database file.
      def drop
        load_database
        ActiveRecord::Base.connection.disconnect!
        File.delete(database_path) if database_path && File.exist?(database_path)
        out.puts "drop #{relative_database_path}"
      end

      # Loads `db/seeds.rb` (raises if missing). The full application is loaded first so
      # seeds can reference app models.
      def seed
        load_database
        load_application
        raise Generators::Error, "Missing file: db/seeds.rb" unless File.exist?(seed_path)

        load seed_path
        out.puts "seed db/seeds.rb"
      end

      # Creates the database, loads the schema when one exists (otherwise migrates), and seeds.
      def setup
        create
        File.exist?(schema_path) ? schema_load : migrate
        seed if File.exist?(seed_path)
        out.puts "setup #{relative_database_path}"
      end

      # Drops and re-creates the database from scratch (drop + setup).
      def reset
        load_database
        drop
        setup
      end

      # CI-friendly: sets up the database when it doesn't exist, otherwise just migrates.
      def prepare
        load_database
        if database_path && File.exist?(database_path)
          migrate
        else
          setup
        end
      end

      # Prints a Rails-style migration status table (status, version, name).
      def status
        load_database
        out.puts "Status   Version          Name"
        out.puts "-" * 48
        migration_context.migrations_status.each do |migration_status, version, name|
          out.puts format("%-8s %-16s %s", migration_status, version, name)
        end
      end

      # Prints the current schema version.
      def version
        load_database
        out.puts "version #{migration_context.current_version}"
      end

      # Writes the current database structure to `db/schema.rb`.
      def schema_dump
        load_database
        dump_schema
        out.puts "dump db/schema.rb"
      end

      # Loads `db/schema.rb` into the database (fast alternative to replaying migrations).
      def schema_load
        load_database
        raise Generators::Error, "Missing file: db/schema.rb. Run `charming db:schema:dump` first." unless File.exist?(schema_path)

        load schema_path
        out.puts "load db/schema.rb"
      end

      # Dumps the connected database's structure to `db/schema.rb` via ActiveRecord.
      def dump_schema
        File.open(schema_path, "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, file)
        end
      end

      # Parses the `STEP=n` argument for db:rollback (defaults to 1).
      def step_argument
        step = args.find { |arg| arg.start_with?("STEP=") }
        return 1 unless step

        value = step.delete_prefix("STEP=").to_i
        raise Generators::Error, "STEP must be a positive integer" unless value.positive?

        value
      end

      # Loads the app's `config/database.rb` (raises if missing) which establishes the connection.
      def load_database
        database_config = File.join(destination, "config", "database.rb")
        raise Generators::Error, "Database support is not configured. Missing config/database.rb." unless File.exist?(database_config)

        require database_config
      end

      # Requires the app's root loader (`lib/<app>.rb`, derived from the gemspec name) so
      # app constants — models in particular — are available. No-op when not in an app root.
      def load_application
        gemspec = Dir.glob(File.join(destination, "*.gemspec")).first
        return unless gemspec

        root_file = File.join(destination, "lib", "#{File.basename(gemspec, ".gemspec")}.rb")
        require root_file if File.exist?(root_file)
      end

      # The ActiveRecord migration context rooted at `db/migrate` inside the app.
      def migration_context
        ActiveRecord::MigrationContext.new(File.join(destination, "db", "migrate"))
      end

      # Path to the app's `db/schema.rb`.
      def schema_path
        File.join(destination, "db", "schema.rb")
      end

      # Path to the app's `db/seeds.rb`.
      def seed_path
        File.join(destination, "db", "seeds.rb")
      end

      # The configured database file path (nil when ActiveRecord isn't connected to a file).
      def database_path
        ActiveRecord::Base.connection_db_config.database
      end

      # The database path relative to the app root, used for human-friendly status output.
      def relative_database_path
        return "database" unless database_path

        base = File.realpath(destination)
        path = File.expand_path(database_path)
        path.start_with?("#{base}/") ? path.delete_prefix("#{base}/") : path
      end
    end
  end
end
