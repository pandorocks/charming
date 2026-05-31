# frozen_string_literal: true

module Charming
  class CLI
    def initialize(out: $stdout, err: $stderr, pwd: Dir.pwd)
      @out = out
      @err = err
      @pwd = pwd
    end

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

    attr_reader :out, :err, :pwd

    def new_app(args)
      force = args.delete("--force")
      database = extract_database(args)
      name = args.fetch(0) { raise Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]" }
      raise Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]" if args.length > 1

      Generators::AppGenerator.new(name, out: out, destination: pwd, force: force, database: database).generate
      0
    end

    def generate(args)
      force = args.delete("--force")
      type = args.shift || raise(Generators::Error, "Usage: charming generate TYPE NAME [actions]")
      generator(type, args, force).generate
      0
    end

    def generator(type, args, force)
      name = args.shift || raise(Generators::Error, "Usage: charming generate #{type} NAME")
      generator_class(type).new(name, args, out: out, destination: pwd, force: force)
    end

    def generator_class(type)
      {
        "controller" => Generators::ControllerGenerator,
        "model" => Generators::ModelGenerator,
        "screen" => Generators::ScreenGenerator,
        "view" => Generators::ViewGenerator,
        "component" => Generators::ComponentGenerator
      }.fetch(type) { raise Generators::Error, "Unknown generator: #{type}" }
    end

    def database(command, args)
      if command == "db:install"
        database = args.shift || raise(Generators::Error, "Usage: charming db:install sqlite3")
        raise Generators::Error, "Usage: charming db:install sqlite3" if args.any?

        DatabaseInstaller.new(database, out: out, destination: pwd).install
      else
        raise Generators::Error, "Usage: charming #{command}" if args.any?

        DatabaseCommands.new(command, out: out, destination: pwd).run
      end
      0
    end

    def extract_database(args)
      inline = args.find { |arg| arg.start_with?("--database=") }
      return validate_database(args.delete(inline).split("=", 2).last) if inline

      index = args.index("--database")
      return nil unless index

      args.delete_at(index)
      validate_database(args.delete_at(index) || raise(Generators::Error, "Usage: charming new NAME [--database sqlite3] [--force]"))
    end

    def validate_database(database)
      return database if database == "sqlite3"

      raise Generators::Error, "Unsupported database: #{database.inspect}"
    end

    def usage(status)
      err.puts "Usage: charming new NAME | charming generate TYPE NAME [args] | charming db:COMMAND"
      status
    end
  end
end
