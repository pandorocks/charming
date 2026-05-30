# frozen_string_literal: true

module DemoApp
  class ApplicationController < Charming::Controller
    layout Layouts::Application
    focus_ring :sidebar, :content

    key "p", :open_command_palette
    key "q", :quit

    command "Home" do
      navigate_to "/"
    end

    command "Theme", :open_theme_palette
    command "Close palette", :close_command_palette
    command "Quit app", :quit
  end
end
