# frozen_string_literal: true

module DemoApp
  class AppFrameComponent < Charming::Component
    def render
      lines = [title_line, status_line, message_line, markdown_line, help_line]
      lines.insert(2, *loading_lines) if status == "Loading"
      column(*lines, gap: 1)
    end

    private

    def title_line
      text title, style: theme.title
    end

    def help_line
      text "Tab content, r async task. p commands, q quit.", style: theme.muted
    end

    def status_line
      text "Status: #{status}", style: status_style
    end

    def progress_bar_line
      render_component(Charming::Components::Progressbar.new(total: 32, label: "Working").update(progress))
    end

    def activity_indicator_line
      render_component(Charming::Components::ActivityIndicator.new(
        width: 32,
        label: "Working",
        index: activity_index,
        seed: "demo-loading"
      ))
    end

    def loading_lines
      [progress_bar_line, activity_indicator_line]
    end

    def message_line
      text message, style: theme.text
    end

    def markdown_line
      render_component(Charming::Components::Markdown.new(
        content: markdown_content,
        width: 48,
        theme: theme
      ))
    end

    def markdown_content
      <<~MARKDOWN
        ## Markdown Preview

        Charming renders **Markdown** with `Kramdown` and Rouge:

        ~~~ ruby
        render_component Charming::Components::Markdown.new(content: readme)
        ~~~
      MARKDOWN
    end

    def status_style
      return theme.warn if status == "Loading"
      return theme.warn if status == "Error"
      return theme.info if status == "Loaded"

      theme.muted
    end
  end
end
