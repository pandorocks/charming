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
      end
    end
  end
end
