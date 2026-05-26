# frozen_string_literal: true

module DemoApp
  class AppFrameComponent < Charming::Component
    def render
      stacked ? column(counter_card, activity_log, gap: 1) : row(counter_card, activity_log, gap: 2)
    end

    private

    def counter_card
      box(column(title_line, count_line, help_line, gap: 1), style: counter_style)
    end

    def activity_log
      box(column(log_title, render_component(log_viewport), log_help, gap: 1), style: log_style)
    end

    def title_line
      text home.title, style: style.bold.align(:center).width(28)
    end

    def count_line
      text "Count: #{home.count}  #{render_component(spinner)}", style: style.foreground(:bright_white).bold
    end

    def help_line
      text "up/down changes count\nj/k scrolls log\np commands, q quits",
           style: style.foreground(:bright_black)
    end

    def log_title
      text "Activity log", style: style.bold.align(:center).width(30)
    end

    def log_help
      text "j/k, page up/down, home/end", style: style.foreground(:bright_black)
    end

    def counter_style
      base = style.foreground(:bright_cyan).border(:rounded).padding(1, 3).width(28)
      dimmed ? base.faint : base
    end

    def log_style
      base = style.foreground(:bright_blue).border(:rounded).padding(1, 3).width(30)
      dimmed ? base.faint : base
    end
  end
end
