# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module ViewTemplate
        def executable
          %(#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "#{name.snake_name}"

Charming.run(#{name.class_name}::Application.new)
)
        end

        def root_file
          %(# frozen_string_literal: true

require "charming"
require "zeitwerk"
#{database_require}

module #{name.class_name}
end

loader = Zeitwerk::Loader.new
loader.tag = "#{name.snake_name}"
loader.inflector.inflect("version" => "VERSION")
loader.push_dir(File.expand_path("#{name.snake_name}", __dir__), namespace: #{name.class_name})
#{model_loader}loader.push_dir(File.expand_path("../app/state", __dir__), namespace: #{name.class_name})
loader.push_dir(File.expand_path("../app/components", __dir__), namespace: #{name.class_name})
loader.push_dir(File.expand_path("../app/views", __dir__), namespace: #{name.class_name})
loader.push_dir(File.expand_path("../app/controllers", __dir__), namespace: #{name.class_name})
loader.setup

require_relative "../config/routes"
)
        end

        def application
          %(# frozen_string_literal: true

module #{name.class_name}
  class Application < Charming::Application
    root File.expand_path("../..", __dir__)

    Charming::Presentation::UI::Theme.built_in_names.each do |theme_name|
      theme theme_name.to_sym, built_in: theme_name
    end

    default_theme :phosphor
  end
end
)
        end

        def version
          %(# frozen_string_literal: true

module #{name.class_name}
  VERSION = "0.1.0"
end
)
        end

        def view
          %(# frozen_string_literal: true

module #{name.class_name}
  module Home
    class ShowView < Charming::Presentation::View
      def render
        column(title_line, help_line, gap: 1)
      end

      private

      def title_line
        text home.title, style: theme.title
      end

      def help_line
        text "Press p for commands, q to quit.", style: theme.muted
      end
    end
  end
end
)
        end

        def database_require
          database? ? %(require_relative "../config/database") : ""
        end

        def model_loader
          database? ? %(loader.push_dir(File.expand_path("../app/models", __dir__), namespace: #{name.class_name})
) : ""
        end
      end
    end
  end
end
