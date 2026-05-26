# frozen_string_literal: true

require_relative "base"
require_relative "name"

module Charming
  module Generators
    class AppFileGenerator < Base
      def initialize(name, _args, out:, destination:, force: false)
        super(out: out, destination: destination, force: force)
        @name = Name.new(name)
        @app_name = Name.new(app_name_from_gemspec)
      end

      private

      attr_reader :name, :app_name

      def app_path(*parts)
        File.join(*parts, "#{name.snake_name}_#{suffix}.rb")
      end

      def app_name_from_gemspec
        gemspec = Dir.glob(File.join(destination, "*.gemspec")).first
        raise Error, "Run this generator from a Charming app root" unless gemspec

        File.basename(gemspec, ".gemspec")
      end
    end
  end
end
