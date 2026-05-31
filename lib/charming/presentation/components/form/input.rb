# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Input < Field
          def initialize(name, value: "", placeholder: "", width: nil, **options)
            super(name, **options)
            @initial_value = value
            @placeholder = placeholder
            @width = width
          end

          def bind(state)
            super
            state[:values][name] = @initial_value if state[:values][name].nil?
            field_state[:cursor] = state[:values][name].to_s.length unless field_state.key?(:cursor)
          end

          def handle_key(event)
            text_input = input
            result = text_input.handle_key(event)
            return nil unless result == :handled

            state[:values][name] = text_input.value
            field_state[:cursor] = text_input.cursor
            :handled
          end

          private

          def default_value
            @initial_value
          end

          def render_control
            "#{label}: #{input.render}"
          end

          def input
            TextInput.new(
              value: value.to_s,
              placeholder: @placeholder,
              width: @width,
              cursor: field_state[:cursor]
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
