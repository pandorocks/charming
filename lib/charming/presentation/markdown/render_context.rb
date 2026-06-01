# frozen_string_literal: true

module Charming
  module Presentation
    module Markdown
      RenderContext = Data.define(:list_depth, :width) do
        def self.from(width:, list_depth: 0)
          new(list_depth: list_depth, width: width)
        end

        def nested(depth_increment: 0, width: self.width)
          self.class.new(list_depth: list_depth + depth_increment, width: width)
        end
      end
    end
  end
end
