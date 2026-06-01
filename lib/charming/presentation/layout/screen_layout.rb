# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      class ScreenLayout
        def initialize(screen:, background: nil)
          @screen = screen
          @background = background
          @child = nil
          @overlays = []
        end

        def add_child(node)
          raise ArgumentError, "screen_layout accepts one root layout node" if child

          @child = node
        end

        def add_overlay(node)
          overlays << node
        end

        def focusable_names
          child ? child.focusable_names : []
        end

        def render
          body = UI.place(render_child, width: screen.width, height: screen.height, background: background)

          overlays.reduce(body) do |current, overlay|
            UI.overlay(current, overlay.render, top: overlay.top, left: overlay.left)
          end
        end

        private

        attr_reader :screen, :background, :child, :overlays

        def render_child
          return "" unless child

          child.render(Rect.new(x: 0, y: 0, width: screen.width, height: screen.height))
        end
      end
    end
  end
end
