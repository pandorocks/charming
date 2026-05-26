# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
      module ControllerTemplate
        def application_controller
          %(# frozen_string_literal: true

module #{name.class_name}
  class ApplicationController < Charming::Controller
    layout Layouts::Application

    key "p", :open_command_palette
    key "q", :quit
    key "tab", :focus_sidebar

    command "Home" do
      navigate_to "/"
    end

    command "Close palette", :close_command_palette
    command "Quit app", :quit
  end
end
)
        end

        def controller
          %(# frozen_string_literal: true

module #{name.class_name}
  class HomeController < ApplicationController
#{controller_actions}
#{controller_helpers}
  end
end
)
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
      render HomeView.new(home: home, palette: command_palette, screen: screen)
    end

    def home
      model(:home, HomeModel)
    end)
        end
      end
    end
  end
end
