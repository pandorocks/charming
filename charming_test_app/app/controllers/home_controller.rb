# frozen_string_literal: true

module CharmingTestApp
  class HomeController < ApplicationController
    def show
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
