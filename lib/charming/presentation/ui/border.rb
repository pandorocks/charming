# frozen_string_literal: true

module Charming
  module Presentation
    module UI
      class Border
        attr_reader :top_left, :top_right, :bottom_left, :bottom_right, :horizontal, :vertical

        def initialize(corners:, edges:)
          @top_left, @top_right, @bottom_left, @bottom_right = corners
          @horizontal, @vertical = edges
        end

        def self.fetch(name)
          STYLES.fetch(name.to_sym)
        end
      end

      Border::STYLES = {
        normal: Border.new(
          corners: ["+", "+", "+", "+"], edges: ["-", "|"]
        ),
        rounded: Border.new(
          corners: ["╭", "╮", "╰", "╯"], edges: ["─", "│"]
        ),
        thick: Border.new(
          corners: ["┏", "┓", "┗", "┛"], edges: ["━", "┃"]
        ),
        double: Border.new(
          corners: ["╔", "╗", "╚", "╝"], edges: ["═", "║"]
        )
      }.freeze
    end
  end
end
