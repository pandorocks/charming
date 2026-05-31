# frozen_string_literal: true

require "fileutils"

module Charming
  class DatabaseInstaller
    def initialize(database, out:, destination:)
      @database = database
      @out = out
      @destination = destination
      @app_name = Generators::Name.new(app_name_from_gemspec)
    end

    def install
      raise Generators::Error, "Unsupported database: #{database.inspect}" unless database == "sqlite3"

      create_file("config/database.rb", database_config)
      create_file("app/models/application_record.rb", application_record)
      create_file("db/migrate/.keep", "")
      create_file("db/seeds.rb", %(# frozen_string_literal: true
))
      update_gemspec
      update_root_file
    end

    private

    attr_reader :database, :out, :destination, :app_name

    def create_file(path, content)
      absolute_path = File.join(destination, path)
      if File.exist?(absolute_path)
        out.puts "exist #{path}"
        return
      end

      FileUtils.mkdir_p(File.dirname(absolute_path))
      File.write(absolute_path, content)
      out.puts "create #{path}"
    end

    def update_gemspec
      update_file(gemspec_path) do |current|
        updated = current.sub('Dir.glob("{app,config,exe,lib}/**/*")', 'Dir.glob("{app,config,db,exe,lib}/**/*")')
        updated = insert_dependency(updated, "activerecord", "~> 8.1")
        insert_dependency(updated, "sqlite3", "~> 2.0")
      end
    end

    def update_root_file
      update_file(root_file_path) do |current|
        updated = current
        updated = updated.sub(%(require "zeitwerk"\n), %(require "zeitwerk"\nrequire_relative "../config/database"\n)) unless updated.include?(%(require_relative "../config/database"))
        unless updated.include?(%[loader.push_dir(File.expand_path("../app/models", __dir__), namespace: #{app_name.class_name})])
          updated = updated.sub(
            %[loader.push_dir(File.expand_path("../app/state", __dir__), namespace: #{app_name.class_name})\n],
            %[loader.push_dir(File.expand_path("../app/models", __dir__), namespace: #{app_name.class_name})\nloader.push_dir(File.expand_path("../app/state", __dir__), namespace: #{app_name.class_name})\n]
          )
        end
        updated
      end
    end

    def update_file(path)
      raise Generators::Error, "Missing file: #{relative_path(path)}" unless File.exist?(path)

      current = File.read(path)
      updated = yield current
      return if updated == current

      File.write(path, updated)
      out.puts "update #{relative_path(path)}"
    end

    def insert_dependency(content, gem_name, version)
      return content if content.include?(%(spec.add_dependency "#{gem_name}"))

      dependency = %(  spec.add_dependency "#{gem_name}", "#{version}")
      content.sub(%(  spec.add_dependency "charming"\n), %(  spec.add_dependency "charming"\n#{dependency}\n))
    end

    def database_config
      %(# frozen_string_literal: true

require "active_record"
require "fileutils"

database_path = File.expand_path("../db/development.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(database_path))

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: database_path
)
)
    end

    def application_record
      %(# frozen_string_literal: true

module #{app_name.class_name}
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
)
    end

    def app_name_from_gemspec
      File.basename(gemspec_path, ".gemspec")
    end

    def gemspec_path
      @gemspec_path ||= Dir.glob(File.join(destination, "*.gemspec")).first || raise(Generators::Error, "Run this command from a Charming app root")
    end

    def root_file_path
      File.join(destination, "lib", "#{app_name.snake_name}.rb")
    end

    def relative_path(path)
      path.delete_prefix("#{destination}/")
    end
  end
end
