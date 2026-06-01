# frozen_string_literal: true

require "fileutils"

module Charming
  # DatabaseCommands implements the runtime side of `charming db:COMMAND` (other than
  # `db:install`, which lives in DatabaseInstaller). It loads the app's `config/database.rb`,
  # delegates the actual work to ActiveRecord, and prints a short status line on success.
  class DatabaseCommands
    # *command* is the subcommand string (e.g., "db:create"). *out* is the status-output
    # stream. *destination* is the app root for resolving `config/database.rb` and `db/`.
    def initialize(command, out:, destination:)
      @command = command
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
      else raise Generators::Error, "Unknown database command: #{command}"
      end
    end

    private

    # The subcommand, output stream, and app destination.
    attr_reader :command, :out, :destination

    # Creates the SQLite database file (touch) and establishes the connection.
    def create
      load_database
      FileUtils.mkdir_p(File.dirname(database_path)) if database_path
      FileUtils.touch(database_path) if database_path
      ActiveRecord::Base.connection
      out.puts "create #{relative_database_path}"
    end

    # Runs all pending migrations from `db/migrate`.
    def migrate
      load_database
      migration_context.migrate
      out.puts "migrate db/migrate"
    end

    # Rolls back the most recent migration.
    def rollback
      load_database
      migration_context.rollback(1)
      out.puts "rollback db/migrate"
    end

    # Disconnects ActiveRecord, then deletes the database file.
    def drop
      load_database
      ActiveRecord::Base.connection.disconnect!
      File.delete(database_path) if database_path && File.exist?(database_path)
      out.puts "drop #{relative_database_path}"
    end

    # Loads `db/seeds.rb` (raises if missing).
    def seed
      load_database
      seed_path = File.join(destination, "db", "seeds.rb")
      raise Generators::Error, "Missing file: db/seeds.rb" unless File.exist?(seed_path)

      load seed_path
      out.puts "seed db/seeds.rb"
    end

    # Loads the app's `config/database.rb` (raises if missing) which establishes the connection.
    def load_database
      database_config = File.join(destination, "config", "database.rb")
      raise Generators::Error, "Database support is not configured. Missing config/database.rb." unless File.exist?(database_config)

      require database_config
    end

    # The ActiveRecord migration context rooted at `db/migrate` inside the app.
    def migration_context
      ActiveRecord::MigrationContext.new(File.join(destination, "db", "migrate"))
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
