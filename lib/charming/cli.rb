# frozen_string_literal: true

require_relative "generators"

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
      name = args.fetch(0) { raise Generators::Error, "Usage: charming new NAME [--force]" }
      Generators::AppGenerator.new(name, out: out, destination: pwd, force: force).generate
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
        "screen" => Generators::ScreenGenerator,
        "view" => Generators::ViewGenerator,
        "component" => Generators::ComponentGenerator
      }.fetch(type) { raise Generators::Error, "Unknown generator: #{type}" }
    end

    def usage(status)
      err.puts "Usage: charming new NAME | charming generate TYPE NAME [actions]"
      status
    end
  end
end
