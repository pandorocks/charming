# frozen_string_literal: true

module CharmingTestApp
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
