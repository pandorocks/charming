# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
      module ComponentTemplates
        def component
          %(# frozen_string_literal: true

module #{name.class_name}
  class AppFrameComponent < Charming::Component
    def render
      box(column(title_line, help_line, gap: 1), style: frame_style)
    end
#{component_helpers}
  end
end
)
        end

        def command_palette_modal_component
          %(# frozen_string_literal: true

module #{name.class_name}
  class CommandPaletteModalComponent < Charming::Component
    def render
      box(column(title_line, help_line, render_component(palette), gap: 1), style: modal_style)
    end
#{command_palette_modal_helpers}
  end
end
)
        end

        def component_helpers
          %(
    private

    def title_line
      text title, style: style.bold.align(:center).width(40)
    end

    def help_line
      text "Press p for commands, q to quit.", style: style.foreground(:bright_black)
    end

    def frame_style
      base = style.foreground(:bright_cyan).border(:rounded).padding(1, 3).width(40)
      dimmed ? base.faint : base
    end)
        end

        def command_palette_modal_helpers
          %(
    private

    def title_line
      text "Command palette", style: style.bold.align(:center).width(44)
    end

    def help_line
      text "Type to filter. Enter selects. Escape closes.", style: style.foreground(:bright_black)
    end

    def modal_style
      style.foreground(:bright_magenta).border(:double).padding(1, 3).width(52)
    end)
        end
      end
    end
  end
end
