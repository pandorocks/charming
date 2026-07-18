# frozen_string_literal: true

module Charming
  module Markdown
    # TableRenderer formats parsed Markdown table rows for terminal display.
    class TableRenderer
      def initialize(rows:, style:)
        @rows = rows
        @style = style
      end

      def render
        return "" if rows.empty?

        rows.each_with_index.map { |row, index| render_row(row, index) }.join("\n")
      end

      private

      attr_reader :rows, :style

      def render_row(row, index)
        line = table_row(row)
        index.zero? ? [line, table_separator].join("\n") : line
      end

      def table_row(row)
        cells = widths.each_with_index.map { |width, index| table_cell(row, width, index) }
        "#{separator}#{cells.join(separator)}#{separator}"
      end

      def table_cell(row, width, index)
        " #{UI::Width.pad_to(row[index].to_s, width)} "
      end

      def table_separator
        "#{separator}#{widths.map { |table_width| row_separator * (table_width + 2) }.join(separator)}#{separator}"
      end

      def widths
        @widths ||= Array.new(column_count) do |index|
          UI::Width.widest(rows.map { |row| row[index].to_s })
        end
      end

      def column_count
        rows.map(&:length).max || 0
      end

      def separator
        style.column_separator || "|"
      end

      def row_separator
        style.row_separator || "-"
      end
    end
  end
end
