# frozen_string_literal: true

require "tty-table"

module Charming
  module Presentation
    module Components
      class Table < Component
        include KeyboardHandler

        KEY_ACTIONS = {
          up: :move_up,
          down: :move_down,
          home: :move_home,
          end: :move_end
        }.freeze

        HEADER_HEIGHT = 2

        attr_reader :header, :rows, :selected_index

        def initialize(header:, rows: [], selected_index: 0)
          super()
          @header = Array(header).map(&:to_s)
          @rows = Array(rows)
          @selected_index = clamp_index(selected_index)
        end

        def handle_key(event)
          return nil if rows.empty?

          case Charming.key_of(event)
          when :enter then [:selected, selected_row]
          else super
          end
        end

        def handle_mouse(event)
          return nil if rows.empty?
          return nil unless event.respond_to?(:click?) && event.click?

          clicked = event.y - HEADER_HEIGHT
          return nil if clicked.negative? || clicked >= rows.length

          @selected_index = clicked
          :handled
        end

        def selected_row
          rows[selected_index]
        end

        def render
          return "(empty table)" if header.empty? && rows.empty?

          normalized = rows.map { |row| normalize_row(row) }
          lines = TTY::Table.new(header: header, rows: normalized)
            .render(:unicode)
            .lines(chomp: true)

          compact_layout(lines)
        end

        private

        def normalize_row(row)
          cells = case row
          when Hash then row.values
          when String then [row]
          else Array(row)
          end
          return cells if header.length <= 1 || cells.length <= header.length

          kept = cells.first(header.length - 1)
          merged = cells[(header.length - 1)..].join(" ")
          kept + [merged]
        end

        def compact_layout(lines)
          return lines.join("\n") if lines.length < 4

          top, header_line, _separator, *rest = lines
          body = rest.first(rows.length)
          bottom = rest[rows.length]

          highlighted = body.each_with_index.map do |line, index|
            (index == selected_index) ? "\e[7m#{line}\e[m" : line
          end

          [top, header_line, *highlighted, bottom].compact.join("\n")
        end

        def move_up
          @selected_index -= 1 if selected_index.positive?
        end

        def move_down
          @selected_index += 1 if selected_index < rows.length - 1
        end

        def move_home
          @selected_index = 0
        end

        def move_end
          @selected_index = rows.length - 1
        end

        def clamp_index(value)
          return 0 if rows.empty?

          value.to_i.clamp(0, rows.length - 1)
        end
      end
    end
  end
end
