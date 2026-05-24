# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
      module ControllerTemplate
        def controller
          %(# frozen_string_literal: true

module #{name.class_name}
  class HomeController < Charming::Controller
#{controller_key_bindings}
#{controller_commands}
#{controller_actions}
#{controller_helpers}
  end
end
)
        end

        def controller_key_bindings
          %(    key "p", :open_command_palette
    key "q", :quit)
        end

        def controller_commands
          %(
    command "Close palette", :close_command_palette
    command "Quit app", :quit)
        end

        def controller_actions
          %(
    def show
      render_home
    end)
        end

        def controller_helpers
          %(

    private
#{render_helpers})
        end

        def render_helpers
          %(
    def render_home
      render HomeView.new(home: home, palette: command_palette)
    end

    def home
      model(:home, HomeModel)
    end)
        end
      end
    end
  end
end
