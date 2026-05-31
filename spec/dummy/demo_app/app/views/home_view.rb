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
        activity_index: home.activity_index,
        message: home.message,
        theme: theme
      )
    end
  end
end
