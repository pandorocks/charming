# frozen_string_literal: true

module DemoApp
  class HomeController < ApplicationController
    key "r", :refresh
    on_task :refresh_home, action: :refresh_loaded

    def show
      render_home
    end

    def refresh
      home.status = "Loading"
      home.message = "Async task running. Press q to quit while it works."
      run_task(:refresh_home) do
        sleep 2
        "Async task finished."
      end
      render_home
    end

    def refresh_loaded
      home.status = event.error? ? "Error" : "Loaded"
      home.message = event.error? ? event.error.message : event.value
      render_home
    end

    private

    def render_home
      render HomeView.new(home: home, palette: command_palette, screen: screen)
    end

    def home
      model(:home, HomeModel)
    end
  end
end
