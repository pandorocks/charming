# frozen_string_literal: true

module Charming
  module Presentation
    # Layout contains generic screen-size math and composition helpers. It is
    # intentionally unaware of application shells such as sidebars or nav panes.
    module Layout
      module_function

      def clamp_size(value, min: nil, max: nil)
        size = value.to_i
        size = [size, min].max if min
        size = [size, max].min if max
        size
      end

      def available_width(screen, reserved: 0, min: nil, max: nil)
        clamp_size(screen.width - reserved, min: min, max: max)
      end

      def available_height(screen, reserved: 0, min: nil, max: nil)
        clamp_size(screen.height - reserved, min: min, max: max)
      end

      def stack_or_row(*blocks, narrow:, gap: 0)
        if narrow
          UI.join_vertical(*blocks, gap: gap)
        else
          UI.join_horizontal(*blocks, gap: gap)
        end
      end

      def selected_window_start(selected_index:, item_count:, window_size:)
        count = item_count.to_i
        size = [window_size.to_i, 1].max
        selected = selected_index.to_i.clamp(0, [count - 1, 0].max)
        max_start = [count - size, 0].max

        (selected - size + 1).clamp(0, max_start)
      end
    end
  end
end
