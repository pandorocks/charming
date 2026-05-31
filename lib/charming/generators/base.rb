# frozen_string_literal: true

require "fileutils"

module Charming
  module Generators
    class Base
      def initialize(out:, destination:, force: false)
        @out = out
        @destination = destination
        @force = force
      end

      private

      attr_reader :out, :destination

      def create_file(path, content, executable: false)
        absolute_path = File.join(destination, path)
        raise Error, "File already exists: #{path}" if File.exist?(absolute_path) && !@force

        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, content)
        FileUtils.chmod("u+x,go+rx", absolute_path) if executable
        out.puts "create #{path}"
      end
    end
  end
end
