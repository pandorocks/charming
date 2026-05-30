# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module ComponentTemplates
        def component
          %(# frozen_string_literal: true

module #{name.class_name}
  class AppFrameComponent < Charming::Component
    def render
      column(title_line, help_line, gap: 1)
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
      text title, style: style.bold.foreground(:bright_cyan)
    end

    def help_line
      text "Press p for commands, q to quit.", style: style.foreground(:bright_black)
    end)
        end
      end
    end
  end
end
