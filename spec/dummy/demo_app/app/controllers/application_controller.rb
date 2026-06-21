# frozen_string_literal: true

module DemoApp
  class ApplicationController < Charming::Controller
    layout Layouts::ApplicationLayout
    focus_ring :sidebar, :content

    key "ctrl+p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global

    command "Home" do
      navigate_to "/"
    end

    command "Theme", :open_theme_palette

    command "LG Layout" do
      navigate_to "/lg"
    end

    command "Image" do
      navigate_to "/image"
    end

    command "Charts" do
      navigate_to "/charts"
    end

    command "Close palette", :close_command_palette
    command "Quit app", :quit
  end
end
