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

      # Inserts *content* into *path* just before the line matching *end_line*. No-ops when
      # the content is already present. Raises Error when the file or end-line is missing.
      def insert_before_end(path, content, label, end_line)
        raise Error, "Missing file: #{relative_path(path)}" unless File.exist?(path)

        current = File.read(path)
        return if current.include?(content)

        lines = current.lines
        index = insertion_index(lines, path, end_line)
        lines.insert(index, "#{content}\n")
        File.write(path, lines.join)
        out.puts "insert #{label} #{relative_path(path)}"
      end

      # Returns the index of the last line in *lines* that matches *end_line* (the line
      # just before which new content will be inserted). Raises Error when not found.
      def insertion_index(lines, path, end_line)
        index = lines.rindex { |line| line.chomp == end_line }
        raise Error, "Could not update #{relative_path(path)}" unless index

        index
      end

      # Strips the destination prefix from *path* for human-friendly status output.
      def relative_path(path)
        path.delete_prefix("#{destination}/")
      end
    end
  end
end
