# frozen_string_literal: true

require "fileutils"

module Charming
  module Generators
    # Base is the parent class for all Charming file generators. Subclasses implement
    # `generate` to write the appropriate files. The base class provides `create_file`,
    # which writes content to a path under the configured *destination* and refuses to
    # overwrite existing files unless *force* was set.
    class Base
      # *out* is the status-output stream. *destination* is the app root for generated files.
      # *force* (default false) allows overwriting existing files.
      def initialize(out:, destination:, force: false)
        @out = out
        @destination = destination
        @force = force
      end

      private

      # Status output stream and destination directory accessor (subclasses use these).
      attr_reader :out, :destination

      # True when overwriting existing files was requested (`--force`).
      def force?
        @force
      end

      # Writes *content* to *path* (relative to the destination), creating intermediate
      # directories as needed. Raises Generators::Error when the file already exists and
      # *force* is false. Marks the file as executable when *executable:* is true.
      def create_file(path, content, executable: false)
        absolute_path = File.join(destination, path)
        raise Error, "File already exists: #{path}" if File.exist?(absolute_path) && !@force

        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, content)
        FileUtils.chmod("u+x,go+rx", absolute_path) if executable
        out.puts "create #{path}"
      end

      # Renders a template file by replacing `__TOKEN__` placeholders with values from
      # *tokens*. *template_path* is relative to the generators templates directory.
      def render_template(template_path, **tokens)
        body = File.read(template_file(template_path))
        tokens.each do |key, value|
          body = body.gsub("__#{key.to_s.upcase}__", value.to_s)
        end
        body
      end

      # Absolute path to a generator template file. *relative_path* is relative to the
      # generators templates directory.
      def template_file(relative_path)
        File.join(__dir__, "templates", relative_path)
      end
    end
  end
end
