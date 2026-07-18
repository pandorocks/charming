# frozen_string_literal: true

module Charming
  module UI
    class Border
      attr_reader :top_left, :top_right, :bottom_left, :bottom_right, :horizontal, :vertical

      def initialize(corners:, edges:)
        @top_left, @top_right, @bottom_left, @bottom_right = corners
        @horizontal, @vertical = edges
      end

      # Resolves *name* to a Border: a Border instance passes through (custom
      # borders), anything else is looked up in the built-in STYLES.
      def self.fetch(name)
        return name if name.is_a?(Border)

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
      ),
      square: Border.new(
        corners: ["┌", "┐", "└", "┘"], edges: ["─", "│"]
      ),
      hidden: Border.new(
        corners: [" ", " ", " ", " "], edges: [" ", " "]
      ),
      block: Border.new(
        corners: ["█", "█", "█", "█"], edges: ["█", "█"]
      )
    }.tap { |styles| styles[:ascii] = styles[:normal] }.freeze
  end
end
