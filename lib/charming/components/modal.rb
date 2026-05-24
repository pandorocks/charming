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
        box(column(*lines, gap: 1), style: modal_style)
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
        @style || style.foreground(:bright_magenta).border(:double).padding(1, 3).width(width)
      end

      def title_width
        [width - 8, 0].max
      end
    end
  end
end
