# frozen_string_literal: true

module DemoApp
  class AppFrameComponent < Charming::Component
    def render
      column(title_line, help_line, gap: 1)
    end

    private

    def title_line
      text title, style: style.bold.foreground(:bright_cyan)
    end

    def help_line
      text "Press p for commands, q to quit.", style: style.foreground(:bright_black)
    end
  end
end
