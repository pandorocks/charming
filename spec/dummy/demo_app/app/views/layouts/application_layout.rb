# frozen_string_literal: true

module DemoApp
  module Layouts
    class ApplicationLayout < Charming::View
      def render
        screen_layout(background: theme.background) do
          split(narrow? ? :vertical : :horizontal, gap: 1) do
            pane(:sidebar, **sidebar_options, border: :rounded, padding: [1, 2], style: sidebar_style) do
              column(app_title, navigation, shortcuts, gap: 1)
            end

            pane(:content, grow: 1, border: :rounded, padding: [1, 2], style: content_style) do
              yield_content
            end
          end

          overlay command_palette_modal if command_palette_modal
        end
      end

      private

      def palette_component
        assigns.fetch(:palette, nil)
      end

      def narrow?
        screen.narrow?(below: 72, min_height: 20)
      end

      def sidebar_options
        narrow? ? {height: [screen.height / 3, 5].max} : {width: 22}
      end

      def sidebar_inner_width
        narrow? ? [screen.width - 6, 20].max : 16
      end

      def app_title
        text "DemoApp", style: theme.header_accent.align(:center).width(sidebar_inner_width)
      end

      def navigation
        column(*nav_items)
      end

      def nav_items
        controller.sidebar_routes.each_with_index.map do |route, index|
          text nav_item_label(route, index), style: nav_item_style(route, index)
        end
      end

      def nav_item_label(route, index)
        cursor = (sidebar_focused? && index == sidebar_index) ? ">" : " "
        active = current_route?(route) ? "\u{25cf}" : " "
        "#{cursor} #{active} #{route.title}"
      end

      def nav_item_style(route, index)
        if sidebar_focused? && index == sidebar_index
          theme.selected
        elsif current_route?(route)
          theme.title
        else
          theme.muted
        end
      end

      def shortcuts
        text "tab focus\np commands\nq quit", style: theme.muted
      end

      def sidebar_style
        focused_style = sidebar_focused? ? theme.title : theme.border
        palette_component ? focused_style.faint : focused_style
      end

      def content_style
        focused_style = content_focused? ? theme.title : theme.border
        palette_component ? focused_style.faint : focused_style
      end

      def command_palette_modal
        return unless palette_component

        render_component Charming::Components::CommandPaletteModal.new(
          content: palette_component,
          theme: theme
        )
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
        controller.current_route?(route)
      end
    end
  end
end
