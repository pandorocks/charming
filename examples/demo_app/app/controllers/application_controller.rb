# frozen_string_literal: true

module DemoApp
  class ApplicationController < Charming::Controller
    key "p", :open_command_palette
    key "q", :quit

    command "Close palette", :close_command_palette
    command "Quit app", :quit

    command "Home" do
      navigate_to "/"
    end
    command "Tables" do
      navigate_to "/tables"
    end
  end
end
