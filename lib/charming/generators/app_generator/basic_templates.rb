# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module BasicTemplates
        def gemfile
          %(# frozen_string_literal: true

source "https://rubygems.org"

gemspec
)
        end

        def rakefile
          %(# frozen_string_literal: true

require "bundler/gem_tasks"
)
        end

        def readme
          %(# #{name.class_name}

A Charming terminal user interface.

Run it with:

```sh
bundle exec #{name.snake_name}
```
)
        end

        def gemspec
          %(# frozen_string_literal: true

require_relative "lib/#{name.snake_name}/version"

Gem::Specification.new do |spec|
#{gemspec_attributes}
#{gemspec_dependencies}
end
)
        end

        def gemspec_attributes
          %(  spec.name = "#{name.snake_name}"
  spec.version = #{name.class_name}::VERSION
  spec.summary = "A Charming terminal user interface."
  spec.authors = ["TODO: Your name"]
  spec.email = ["TODO: Your email"]
  spec.files = Dir.glob("#{gemspec_file_glob}/**/*") + %w[README.md]
  spec.bindir = "exe"
  spec.executables = ["#{name.snake_name}"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["rubygems_mfa_required"] = "true")
        end

        def gemspec_dependencies
          %(
  spec.add_dependency "charming"#{database_dependencies})
        end

        def gemspec_file_glob
          database? ? "{app,config,db,exe,lib}" : "{app,config,exe,lib}"
        end

        def database_dependencies
          return "" unless database?

          %(
  spec.add_dependency "activerecord", "~> 8.1"
  spec.add_dependency "sqlite3", "~> 2.0")
        end
      end
    end
  end
end
