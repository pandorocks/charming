# frozen_string_literal: true

module DemoApp
  module Home
    class ShowView < Charming::View
      def render
        lines = [title_line, status_line, message_line, markdown_line, help_line]
        lines.insert(2, *loading_lines) if home.status == "Loading"
        column(*lines, gap: 1)
      end

      private

      def title_line
        text home.title, style: theme.title
      end

      def help_line
        text "Tab content, r async task. ctrl+p commands, q quit.", style: theme.muted
      end

      def status_line
        text "Status: #{home.status}", style: status_style
      end

      def progress_bar_line
        render_component(Charming::Components::Progressbar.new(total: 32, label: "Working").update(home.progress))
      end

      def activity_indicator_line
        render_component(Charming::Components::ActivityIndicator.new(
          width: 32,
          label: "Working",
          index: home.activity_index,
          seed: "demo-loading"
        ))
      end

      def loading_lines
        [progress_bar_line, activity_indicator_line]
      end

      def message_line
        text home.message, style: theme.text
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

          Charming renders **Markdown** with `Commonmarker` and Rouge:

          ~~~ ruby
          render_component Charming::Components::Markdown.new(content: readme)
          ~~~
        MARKDOWN
      end

      def status_style
        return theme.warn if home.status == "Loading"
        return theme.warn if home.status == "Error"
        return theme.info if home.status == "Loaded"

        theme.muted
      end
    end
  end
end
