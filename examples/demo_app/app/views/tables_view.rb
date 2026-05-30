# frozen_string_literal: true

module DemoApp
  class TablesView < Charming::View
    def render
      body = column(title_line, rendered_table, hint_line, selection_line, gap: 1)
      framed = Charming::UI.center(body, width: screen.width, height: screen.height)
      return framed unless palette

      Charming::UI.overlay(framed, command_palette_modal)
    end

    private

    def title_line
      tables.title
    end

    def rendered_table
      render_component(table)
    end

    def hint_line
      "↑/↓ navigate · home/end jump · enter select · p palette · q quit"
    end

    def selection_line
      return "Press enter to select a row." unless tables.last_selected

      name, age, city = tables.last_selected
      "Selected: #{name} (#{age}) — #{city}"
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
