# frozen_string_literal: true

module DemoApp
  class HomeView < Charming::View
    def render
      body = Charming::UI.center(app_frame, width: screen.width, height: screen.height)
      return body unless palette

      Charming::UI.overlay(body, command_palette_modal)
    end

    private

    def app_frame
      render_component AppFrameComponent.new(
        home: home,
        spinner: spinner,
        log_viewport: log_viewport,
        dimmed: !!palette,
        stacked: screen.width < 78 && screen.height >= 20
      )
    end

    def command_palette_modal
      render_component Charming::Components::Modal.new(
        content: palette,
        title: "Command palette",
        help: "Type to filter. Enter selects. Escape closes.",
        width: 52
      )
    end
  end
end
