# frozen_string_literal: true

module Charming
  module Components
    # Paginator tracks a current page over a collection and renders a compact
    # page indicator: bubbles-style dots ("○ ● ○") or arabic "2/3". Pair it with
    # a List or Table by slicing items through `page_items`.
    class Paginator < Component
      ACTIVE_DOT = "●"
      INACTIVE_DOT = "○"

      attr_reader :page, :per_page, :total

      # *total* is the collection size, *per_page* the page size, *page* the
      # 0-based starting page, and *format* either :dots (default) or :arabic.
      def initialize(total:, per_page:, page: 0, format: :dots, theme: nil)
        super(theme: theme)
        @total = [total.to_i, 0].max
        @per_page = [per_page.to_i, 1].max
        @format = format
        @page = page.to_i.clamp(0, page_count - 1)
      end

      # The number of pages — at least 1, even for an empty collection.
      def page_count
        [(total.to_f / per_page).ceil, 1].max
      end

      # The slice of *items* belonging to the current page.
      def page_items(items)
        items[page * per_page, per_page] || []
      end

      # Advances one page, clamping at the last. Returns self.
      def next_page
        @page = [page + 1, page_count - 1].min
        self
      end

      # Steps back one page, clamping at the first. Returns self.
      def prev_page
        @page = [page - 1, 0].max
        self
      end

      # Renders the page indicator in the configured format.
      def render
        return "#{page + 1}/#{page_count}" if @format == :arabic

        Array.new(page_count) { |index| (index == page) ? ACTIVE_DOT : INACTIVE_DOT }.join(" ")
      end
    end
  end
end
