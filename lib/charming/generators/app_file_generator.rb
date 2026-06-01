# frozen_string_literal: true

module Charming
  module Generators
    # AppFileGenerator is the parent class for "in-app" sub-generators (controller, model,
    # screen, view, component) that run inside an existing Charming app. It derives the
    # app's namespace from the local gemspec and exposes path-building helpers that put
    # files under the right `app/...` subdirectory.
    class AppFileGenerator < Base
      # *name* is the singular resource name (e.g., "user"). *_args* are subcommand-specific
      # (e.g., controller actions or model fields). *out*, *destination*, and *force* are
      # forwarded to Base.
      def initialize(name, _args, out:, destination:, force: false)
        super(out: out, destination: destination, force: force)
        @name = Name.new(name)
        @app_name = Name.new(app_name_from_gemspec)
      end

      private

      # The resource name and the parent app name (both wrapped in Generators::Name).
      attr_reader :name, :app_name

      # Builds the full file path under `app/<dir>/<resource>_<suffix>.rb` for the
      # configured *parts* (the immediate directory chain). The suffix is supplied by
      # the subclass (controller, model, view, etc.).
      def app_path(*parts)
        File.join(*parts, "#{name.snake_name}_#{suffix}.rb")
      end

      # Reads the gemspec filename from the destination directory to derive the app name.
      # Raises Error when no gemspec is found.
      def app_name_from_gemspec
        gemspec = Dir.glob(File.join(destination, "*.gemspec")).first
        raise Error, "Run this generator from a Charming app root" unless gemspec

        File.basename(gemspec, ".gemspec")
      end
    end
  end
end
