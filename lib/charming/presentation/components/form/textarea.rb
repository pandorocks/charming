# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Textarea < Field
          def initialize(name, value: "", placeholder: "", width: nil, height: nil, **options)
            super(name, **options)
            @initial_value = value
            @placeholder = placeholder
            @width = width
            @height = height
          end

          def bind(state)
            super
            state[:values][name] = @initial_value if state[:values][name].nil?
            field_state[:cursor] = state[:values][name].to_s.length unless field_state.key?(:cursor)
            field_state[:offset] ||= 0
          end

          def handle_key(event)
            area = text_area
            result = area.handle_key(event)
            return nil unless result == :handled

            state[:values][name] = area.value
            field_state[:cursor] = area.cursor
            field_state[:offset] = area.offset
            field_state[:preferred_column] = area.preferred_column
            :handled
          end

          def render(active: false)
            label_line = "#{active ? ">" : " "} #{label}:"
            label_line = theme.selected.render(label_line) if active
            [label_line, *body_lines, help_line, *error_lines].compact.join("\n")
          end

          private

          def default_value
            @initial_value
          end

          def body_lines
            text_area.render.lines(chomp: true).map { |line| "  #{line}" }
          end

          def text_area
            TextArea.new(
              value: value.to_s,
              placeholder: @placeholder,
              width: @width,
              height: @height,
              cursor: field_state[:cursor],
              offset: field_state[:offset],
              preferred_column: field_state[:preferred_column]
            )
          end

          def field_state
            state[:fields][name]
          end
        end
      end
    end
  end
end
