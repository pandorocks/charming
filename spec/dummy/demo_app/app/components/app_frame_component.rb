# frozen_string_literal: true

module DemoApp
  class AppFrameComponent < Charming::Component
    def render
      column(title_line, status_line, message_line, help_line, gap: 1)
    end

    private

    def title_line
      text title, style: style.bold.foreground(:bright_cyan)
    end

    def help_line
      text "Press r to run async task, p for commands, q to quit.", style: style.foreground(:bright_black)
    end

    def status_line
      text "Status: #{status}", style: status_style
    end

    def message_line
      text message
    end

    def status_style
      return style.foreground(:yellow) if status == "Loading"
      return style.foreground(:red) if status == "Error"
      return style.foreground(:green) if status == "Loaded"

      style.foreground(:bright_black)
    end
  end
end
