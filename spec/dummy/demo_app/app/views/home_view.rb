# frozen_string_literal: true

module DemoApp
  class HomeView < Charming::View
    def render
      app_frame
    end

    private

    def app_frame
      render_component AppFrameComponent.new(
        title: home.title,
        status: home.status,
        progress: home.progress,
        message: home.message
      )
    end
  end
end
