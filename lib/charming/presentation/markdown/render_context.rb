# frozen_string_literal: true

module Charming
  module Markdown
    # RenderContext carries render-time state that needs to flow down the Markdown AST.
    RenderContext = Data.define(:width, :list_depth, :style, :current_style, :base_url, :source_lines) do
      def self.from(width:, style:, base_url: nil, source_lines: [], list_depth: 0, current_style: nil)
        new(
          width: width,
          list_depth: list_depth,
          style: style,
          current_style: current_style || style[:document],
          base_url: base_url,
          source_lines: source_lines
        )
      end

      def with(width: self.width, list_depth: self.list_depth, current_style: self.current_style)
        self.class.new(
          width: width,
          list_depth: list_depth,
          style: style,
          current_style: current_style,
          base_url: base_url,
          source_lines: source_lines
        )
      end

      def nested_list(width: self.width)
        with(width: width, list_depth: list_depth + 1)
      end

      def inherit(style_name)
        current_style.inherit_visual(style[style_name])
      end
    end
  end
end
