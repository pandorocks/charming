# frozen_string_literal: true

require_relative "../component"

module Charming
  module Components
    class Modal < Component
      def initialize(content:, title: nil, help: nil, width: 52, style: nil)
        super()
        @content = content
        @title = title
        @help = help
        @width = width
        @style = style
      end

      def render
        rendered = box(column(*lines, gap: 1), style: modal_style)
        @style ? rendered : color_border(rendered)
      end

      private

      attr_reader :content, :title, :help, :width

      def lines
        [title_line, help_line, render_content].compact
      end

      def title_line
        text(title, style: style.bold.align(:center).width(title_width)) if title
      end

      def help_line
        text(help, style: style.foreground(:bright_black)) if help
      end

      def render_content
        content.respond_to?(:render) ? render_component(content) : content.to_s
      end

      def modal_style
        @style || style.border(:double).padding(1, 3).width(width)
      end

      def title_width
        [width - 8, 0].max
      end

      def color_border(value)
        value.lines(chomp: true).map.with_index do |line, index|
          border_line?(index, value) ? border_style.render(line) : color_vertical_borders(line)
        end.join("\n")
      end

      def border_line?(index, value)
        index.zero? || index == value.lines.count - 1
      end

      def color_vertical_borders(line)
        return line unless line.start_with?("║") && line.end_with?("║")

        "#{border_style.render("║")}#{line[1...-1]}#{border_style.render("║")}"
      end

      def border_style
        style.foreground(:bright_magenta)
      end
    end
  end
end
