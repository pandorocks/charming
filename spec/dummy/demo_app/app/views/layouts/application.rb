# frozen_string_literal: true

module DemoApp
  module Layouts
    class Application < Charming::View
      def render
        body = Charming::UI.place(app_frame, width: screen.width, height: screen.height)
        return body unless palette

        Charming::UI.overlay(body, command_palette_modal)
      end

      private

      def app_frame
        narrow? ? column(sidebar, main_content, gap: 1) : row(sidebar, main_content, gap: 1)
      end

      def sidebar
        box(column(app_title, navigation, shortcuts, gap: 1), style: sidebar_style)
      end

      def main_content
        box(yield_content, style: main_content_style)
      end

      def app_title
        text "DemoApp", style: style.bold.align(:center).width(sidebar_width)
      end

      def navigation
        column(*nav_items)
      end

      def nav_items
        controller.application.routes.all.each_with_index.map do |route, index|
          text nav_label(route, index), style: nav_style(route, index)
        end
      end

      def nav_label(route, index)
        cursor = (sidebar_focused? && index == sidebar_index) ? ">" : " "
        active = current_route?(route) ? "●" : " "
        "#{cursor} #{active} #{route.title}"
      end

      def nav_style(route, index)
        return theme.primary.bold if sidebar_focused? && index == sidebar_index
        return theme.primary if current_route?(route)

        theme.muted
      end

      def shortcuts
        text "tab focus\np commands\nq quit", style: theme.muted
      end

      def sidebar_focused?
        controller.sidebar_focused?
      end

      def content_focused?
        controller.content_focused?
      end

      def sidebar_index
        controller.sidebar_index
      end

      def current_route?(route)
        route.controller_class == controller.class && route.action == :show
      end

      def command_palette_modal
        render_component Charming::Components::Modal.new(
          content: palette,
          title: "Command palette",
          help: "Type to filter. Enter selects. Escape closes.",
          width: 52,
          theme: theme
        )
      end

      def sidebar_style
        base = sidebar_focused? ? theme.primary : style
        base = base.border(:rounded).padding(1, 2).width(sidebar_width).height(panel_height)
        palette ? base.faint : base
      end

      def main_content_style
        base = content_focused? ? theme.primary : style
        base = base.border(:rounded).padding(1, 2).width(main_content_width).height(panel_height)
        palette ? base.faint : base
      end

      def narrow?
        screen.width < 72 && screen.height >= 20
      end

      def sidebar_width
        narrow? ? [screen.width - 6, 20].max : 22
      end

      def main_content_width
        narrow? ? [screen.width - 6, 20].max : [screen.width - sidebar_width - 13, 20].max
      end

      def panel_height
        return nil if narrow?

        [screen.height - 4, 5].max
      end
    end
  end
end
