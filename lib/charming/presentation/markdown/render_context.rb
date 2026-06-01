# frozen_string_literal: true

module Charming
  module Presentation
    module Markdown
      # RenderContext carries the state needed to render nested Markdown blocks: the current
      # list nesting depth (used for indentation) and the wrap width.
      RenderContext = Data.define(:list_depth, :width) do
        # Builds a new RenderContext with the given *width* and optional starting *list_depth*.
        def self.from(width:, list_depth: 0)
          new(list_depth: list_depth, width: width)
        end

        # Returns a derived context with the list depth incremented by *depth_increment*
        # and the wrap width overridden to *width* (defaults to the current width).
        def nested(depth_increment: 0, width: self.width)
          self.class.new(list_depth: list_depth + depth_increment, width: width)
        end
      end
    end
  end
end
