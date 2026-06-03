# frozen_string_literal: true

module Charming
  # CLI dispatches the `charming` executable's subcommands to the appropriate generators
  # or database commands. Subcommands:
  # - `charming new NAME [--database sqlite3] [--force]` — scaffolds a new app
  # - `charming generate TYPE NAME [args]` — runs a sub-generator (controller, model, screen, view, component)
  # - `charming db:COMMAND` — runs a database command (db:create, db:migrate, db:rollback, db:drop, db:seed, db:install)
  #
  # Generator errors are caught and printed to stderr; the process exits with status 1.
  class CLI
    # *out* defaults to `$stdout`, *err* to `$stderr`, *pwd* to `Dir.pwd` (overridable for tests).
    def initialize(out: $stdout, err: $stderr, pwd: Dir.pwd)
      @out = out
      @err = err
      @pwd = pwd
    end

    # Runs the CLI with the given *argv* array. Returns 0 on success, 1 on a generator error,
    # or the status from `usage` for unknown subcommands.
    def call(argv)
      command, *args = argv
      case command
      when "new" then new_app(args)
      when "generate", "g" then generate(args)
      when /^db:/ then database(command, args)
      else usage(1)
      end
    rescue Generators::Error => e
      err.puts e.message
      1
    end

    private

    # Standard output, standard error, and working directory used for generator destinations.
    attr_reader :out, :err, :pwd

    # Handles `charming new`. Validates args, extracts `--database=` and `--force`,
    # and runs AppGenerator. Returns 0 on success, raises Generators::Error on bad input.
    def new_app(args)
      force = args.delete("--force")
      database = extract_database(args)
      name = args.fetch(0) { raise Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]" }
      raise Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]" if args.length > 1

      Generators::AppGenerator.new(name, out: out, destination: pwd, force: force, database: database).generate
      0
    end

    # Handles `charming generate TYPE NAME [args]`. Extracts `--force` and dispatches to
    # the generator class for the requested type.
    def generate(args)
      force = args.delete("--force")
      type = args.shift || raise(Generators::Error, "Usage: charming generate TYPE NAME [actions]")
      generator(type, args, force).generate
      0
    end

    # Builds the generator instance for the given *type*, popping the name from *args*.
    def generator(type, args, force)
      name = args.shift || raise(Generators::Error, "Usage: charming generate #{type} NAME")
      generator_class(type).new(name, args, out: out, destination: pwd, force: force)
    end

    # Returns the generator class for a *type* string (controller, model, screen, view, component).
    def generator_class(type)
      {
        "controller" => Generators::ControllerGenerator,
        "model" => Generators::ModelGenerator,
        "screen" => Generators::ScreenGenerator,
        "view" => Generators::ViewGenerator,
        "component" => Generators::ComponentGenerator
      }.fetch(type) { raise Generators::Error, "Unknown generator: #{type}" }
    end

    # Routes `db:*` commands to either the install path (db:install) or the generic
    # Database::Commands dispatcher.
    def database(command, args)
      if command == "db:install"
        database = args.shift || raise(Generators::Error, "Usage: charming db:install sqlite3")
        raise Generators::Error, "Usage: charming db:install sqlite3" if args.any?

        Generators::DatabaseInstaller.new(database, out: out, destination: pwd).install
      else
        raise Generators::Error, "Usage: charming #{command}" if args.any?

        Database::Commands.new(command, out: out, destination: pwd).run
      end
      0
    end

    # Extracts the optional `--database=<value>` argument from *args*, removing it in place.
    # Returns the validated database name (currently only "sqlite3") or nil when not given.
    def extract_database(args)
      inline = args.find { |arg| arg.start_with?("--database=") }
      return validate_database(args.delete(inline).split("=", 2).last) if inline

      index = args.index("--database")
      return nil unless index

      args.delete_at(index)
      validate_database(args.delete_at(index) || raise(Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]"))
    end

    # Validates that *database* is a supported adapter name. Currently only "sqlite3".
    def validate_database(database)
      return database if database == "sqlite3"

      raise Generators::Error, "Unsupported database: #{database.inspect}"
    end

    # Prints a usage banner to stderr and returns *status* (1 for unknown commands).
    def usage(status)
      err.puts "Usage: charming new NAME | charming generate TYPE NAME [args] | charming db:COMMAND"
      status
    end
  end
end
