# frozen_string_literal: true

require "fileutils"

module Charming
  class DatabaseCommands
    def initialize(command, out:, destination:)
      @command = command
      @out = out
      @destination = destination
    end

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

    attr_reader :command, :out, :destination

    def create
      load_database
      FileUtils.mkdir_p(File.dirname(database_path)) if database_path
      FileUtils.touch(database_path) if database_path
      ActiveRecord::Base.connection
      out.puts "create #{relative_database_path}"
    end

    def migrate
      load_database
      migration_context.migrate
      out.puts "migrate db/migrate"
    end

    def rollback
      load_database
      migration_context.rollback(1)
      out.puts "rollback db/migrate"
    end

    def drop
      load_database
      ActiveRecord::Base.connection.disconnect!
      File.delete(database_path) if database_path && File.exist?(database_path)
      out.puts "drop #{relative_database_path}"
    end

    def seed
      load_database
      seed_path = File.join(destination, "db", "seeds.rb")
      raise Generators::Error, "Missing file: db/seeds.rb" unless File.exist?(seed_path)

      load seed_path
      out.puts "seed db/seeds.rb"
    end

    def load_database
      database_config = File.join(destination, "config", "database.rb")
      raise Generators::Error, "Database support is not configured. Missing config/database.rb." unless File.exist?(database_config)

      require database_config
    end

    def migration_context
      ActiveRecord::MigrationContext.new(File.join(destination, "db", "migrate"))
    end

    def database_path
      ActiveRecord::Base.connection_db_config.database
    end

    def relative_database_path
      return "database" unless database_path

      base = File.realpath(destination)
      path = File.expand_path(database_path)
      path.start_with?("#{base}/") ? path.delete_prefix("#{base}/") : path
    end
  end
end
