# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Select < Field
          def initialize(name, options:, selected_index: 0, option_label: :to_s.to_proc, **field_options)
            super(name, **field_options)
            @options = options
            @initial_selected_index = selected_index
            @option_label = option_label
          end

          def bind(state)
            super
            ensure_selection
          end

          def handle_key(event)
            selection = list
            result = selection.handle_key(event)
            return nil unless result == :handled

            save_selection(selection.selected_index)
            :handled
          end

          private

          attr_reader :options

          def default_value
            options[clamped_initial_index]
          end

          def render_control
            "#{label}: #{display_value}"
          end

          def display_value
            value.nil? ? "" : @option_label.call(value)
          end

          def list
            List.new(items: options, selected_index: selected_index, label: @option_label, theme: theme)
          end

          def ensure_selection
            if field_state.key?(:selected_index)
              save_selection(field_state[:selected_index])
            elsif state[:values].key?(name)
              save_selection(index_for(state[:values][name]) || clamped_initial_index)
            else
              save_selection(clamped_initial_index)
            end
          end

          def save_selection(index)
            field_state[:selected_index] = clamp_index(index)
            state[:values][name] = options[field_state[:selected_index]]
          end

          def selected_index
            field_state[:selected_index] || clamped_initial_index
          end

          def clamped_initial_index
            clamp_index(@initial_selected_index)
          end

          def clamp_index(index)
            return 0 if options.empty?

            index.to_i.clamp(0, options.length - 1)
          end

          def index_for(option)
            options.index(option)
          end

          def field_state
            state[:fields][name]
          end
        end
      end
    end
  end
end
