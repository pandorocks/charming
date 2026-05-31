# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form < Component
        attr_reader :fields, :state

        def initialize(fields:, state: nil, theme: nil)
          super(theme: theme)
          @fields = fields
          @state = normalize_state(state || {})
          bind_fields
          clamp_focus
        end

        def handle_key(event)
          key = Charming.key_of(event)
          return :cancelled if key == :escape
          return submit if submit_shortcut?(event)
          return move_focus(tab_direction(event)) if key == :tab

          result = handle_current_field(event)
          return result if result

          advance_or_submit if key == :enter
        end

        def values
          state[:values]
        end

        def render
          fields.each_with_index.map do |field, index|
            field.render(active: index == state[:focus_index])
          end.join("\n")
        end

        private

        def normalize_state(value)
          value[:values] ||= {}
          value[:fields] ||= {}
          value[:errors] ||= {}
          value[:focus_index] ||= first_focusable_index || 0
          value
        end

        def bind_fields
          fields.each { |field| field.bind(state) }
        end

        def handle_current_field(event)
          current_field&.handle_key(event)
        end

        def tab_direction(event)
          return -1 if event.respond_to?(:shift) && event.shift

          +1
        end

        def submit_shortcut?(event)
          Charming.key_of(event) == :s && event.respond_to?(:ctrl) && event.ctrl
        end

        def advance_or_submit
          return submit if last_focusable?

          move_focus(+1)
        end

        def submit
          state[:errors] = validation_errors
          focus_first_error unless state[:errors].empty?
          return :handled unless state[:errors].empty?

          [:submitted, values.dup]
        end

        def validation_errors
          fields.each_with_object({}) do |field, errors|
            messages = field.validate
            errors[field.name] = messages unless messages.empty?
          end
        end

        def focus_first_error
          invalid = fields.index { |field| field.focusable? && state[:errors].key?(field.name) }
          state[:focus_index] = invalid if invalid
        end

        def current_field
          fields[state[:focus_index]]
        end

        def move_focus(direction)
          indices = focusable_indices
          return nil if indices.empty?

          current = indices.index(state[:focus_index]) || 0
          state[:focus_index] = indices[(current + direction) % indices.length]
          :handled
        end

        def last_focusable?
          focusable_indices.last == state[:focus_index]
        end

        def focusable_indices
          @focusable_indices ||= fields.each_index.select { |index| fields[index].focusable? }
        end

        def first_focusable_index
          fields.each_index.find { |index| fields[index].focusable? }
        end

        def clamp_focus
          return if focusable_indices.empty?
          return if focusable_indices.include?(state[:focus_index])

          state[:focus_index] = focusable_indices.first
        end
      end
    end
  end
end
