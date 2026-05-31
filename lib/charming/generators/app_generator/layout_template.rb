# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module LayoutTemplate
        def layout
          %(<%
palette_component = assigns.fetch(:palette, nil)
sidebar_focused = controller.sidebar_focused?
content_focused = controller.content_focused?
sidebar_index = controller.sidebar_index
narrow = screen.narrow?(below: 72, min_height: 20)
layout = Charming::Presentation::Layout
sidebar_width = narrow ? layout.available_width(screen, reserved: 6, min: 20) : 22
main_content_width = narrow ? layout.available_width(screen, reserved: 6, min: 20) : layout.clamp_size(screen.width - sidebar_width - 13, min: 20)
panel_height = narrow ? nil : layout.available_height(screen, reserved: 4, min: 5)

app_title = text "#{name.class_name}", style: theme.header_accent.align(:center).width(sidebar_width)
nav_items = controller.sidebar_routes.each_with_index.map do |route, index|
  current_route = controller.current_route?(route)
  cursor = sidebar_focused && index == sidebar_index ? ">" : " "
  active = current_route ? "●" : " "
  item_style = if sidebar_focused && index == sidebar_index
    theme.selected
  elsif current_route
    theme.title
  else
    theme.muted
  end

  text "\#{cursor} \#{active} \#{route.title}", style: item_style
end
navigation = column(*nav_items)
shortcuts = text "tab focus\np commands\nq quit", style: theme.muted

sidebar_style = sidebar_focused ? theme.title : theme.border
sidebar_style = sidebar_style.border(:rounded).padding(1, 2).width(sidebar_width).height(panel_height)
sidebar_style = sidebar_style.faint if palette_component

main_content_style = content_focused ? theme.title : theme.border
main_content_style = main_content_style.border(:rounded).padding(1, 2).width(main_content_width).height(panel_height)
main_content_style = main_content_style.faint if palette_component

sidebar = box(column(app_title, navigation, shortcuts, gap: 1), style: sidebar_style)
main_content = box(yield_content, style: main_content_style)
app_frame = layout.stack_or_row(sidebar, main_content, narrow: narrow, gap: 1)
body = Charming::Presentation::UI.place(app_frame, width: screen.width, height: screen.height)

if palette_component
  command_palette_modal = render_component Charming::Presentation::Components::Modal.new(
    content: palette_component,
    title: "Command palette",
    help: "Type to filter. Enter selects. Escape closes.",
    width: 52,
    theme: theme
  )
  body = Charming::Presentation::UI.overlay(body, command_palette_modal)
end
%><%= body %>
)
        end
      end
    end
  end
end
