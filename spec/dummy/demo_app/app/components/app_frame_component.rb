# frozen_string_literal: true

module DemoApp
  class AppFrameComponent < Charming::Component
    def render
      lines = [title_line, status_line, message_line, help_line]
      lines.insert(2, *loading_lines) if status == "Loading"
      column(*lines, gap: 1)
    end

    private

    def title_line
      text title, style: theme.title
    end

    def help_line
      text "Tab to content, then press r to run async task. p commands, q quit.", style: theme.muted
    end

    def status_line
      text "Status: #{status}", style: status_style
    end

    def progress_bar_line
      render_component(Charming::Components::Progressbar.new(total: 40, label: "Working").update(progress))
    end

    def activity_indicator_line
      render_component(Charming::Components::ActivityIndicator.new(
        width: 40,
        label: "Working",
        index: activity_index,
        seed: "demo-loading"
      ))
    end

    def loading_lines
      [progress_bar_line, activity_indicator_line]
    end

    def message_line
      text message
    end

    def status_style
      return theme.warn if status == "Loading"
      return theme.warn if status == "Error"
      return theme.info if status == "Loaded"

      theme.muted
    end
  end
end
