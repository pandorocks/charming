# frozen_string_literal: true

module Charming
  module Components
    class List < Component
      include KeyboardHandler

      KEY_ACTIONS = {
        up: :move_up,
        down: :move_down,
        home: :move_home,
        end: :move_end
      }.freeze

      attr_reader :items, :selected_index

      def initialize(items:, selected_index: 0, height: nil, label: nil)
        super()
        @items = items
        @selected_index = selected_index
        @height = height
        @label = label || :to_s.to_proc
        clamp_position
      end

      def selected_item
        items[selected_index]
      end

      def handle_key(event)
        key = Charming.key_of(event)
        return [:selected, selected_item] if key.to_sym == :enter && selected_item

        super
      end

      def handle_mouse(event)
        return nil unless event.click?
        return nil unless @height

        visible_start = viewport_start
        visible_end = visible_start + viewport_height

        return nil unless (visible_start...visible_end).cover?(event.y)

        clicked_index = event.y
        @selected_index = clicked_index
        clamp_position
        :handled
      end

      def render
        visible_items.each_with_index.map do |item, index|
          render_item(item, viewport_start + index)
        end.join("\n")
      end

      private

      def move_up
        @selected_index -= 1 if selected_index.positive?
      end

      def move_down
        @selected_index += 1 if selected_index < items.length - 1
      end

      def move_home
        @selected_index = 0
      end

      def move_end
        @selected_index = items.length - 1 unless items.empty?
      end

      def visible_items
        items[viewport_start, viewport_height] || []
      end

      def viewport_start
        return 0 unless @height

        (selected_index - @height + 1).clamp(0, max_viewport_start)
      end

      def viewport_height
        @height || items.length
      end

      def max_viewport_start
        [items.length - @height, 0].max
      end

      def render_item(item, index)
        prefix = (index == selected_index) ? "> " : "  "
        rendered = "#{prefix}#{@label.call(item)}"
        (index == selected_index) ? style.reverse.render(rendered) : rendered
      end

      def clamp_position
        @selected_index = 0 if items.empty?
        @selected_index = selected_index.clamp(0, items.length - 1) unless items.empty?
      end
    end
  end
end
