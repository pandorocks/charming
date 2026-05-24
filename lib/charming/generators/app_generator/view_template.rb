# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
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

require_relative "#{name.snake_name}/version"
require_relative "#{name.snake_name}/application"

#{requires_for("models")}
#{requires_for("components")}
#{requires_for("views")}
#{requires_for("controllers")}

require_relative "../config/routes"
)
        end

        def requires_for(folder)
          path = "../app/#{folder}/#{name.snake_name}/**/*.rb"
          %(Dir[File.expand_path("#{path}", __dir__)].sort.each do |file|
  require file
end)
        end

        def application
          %(# frozen_string_literal: true

module #{name.class_name}
  class Application < Charming::Application
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
  class HomeView < Charming::View
    WIDTH = 80
    HEIGHT = 24

    def render
      screen = Charming::UI.center(app_frame, width: WIDTH, height: HEIGHT)
      return screen unless palette

      Charming::UI.overlay(screen, command_palette_modal)
    end
#{view_helpers}
  end
end
)
        end

        def view_helpers
          %(
    private

    def app_frame
      render_component AppFrameComponent.new(title: home.title, dimmed: !!palette)
    end

    def command_palette_modal
      render_component Charming::Components::Modal.new(
        content: palette,
        title: "Command palette",
        help: "Type to filter. Enter selects. Escape closes.",
        width: 52
      )
    end)
        end
      end
    end
  end
end
