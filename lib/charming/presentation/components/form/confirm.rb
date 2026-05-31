# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Confirm < Field
          def initialize(name, value: false, **options)
            super(name, **options)
            @initial_value = value
          end

          def handle_key(event)
            case Charming.key_of(event)
            when :space
              toggle
            when :y, :right
              state[:values][name] = true
            when :n, :left
              state[:values][name] = false
            else
              return nil unless event.respond_to?(:char) && event.char == " "

              toggle
            end
            :handled
          end

          def validate
            return ["must be accepted"] if required? && value != true

            super
          end

          private

          def default_value
            @initial_value
          end

          def render_control
            "#{checked_marker} #{label}"
          end

          def checked_marker
            value ? "[x]" : "[ ]"
          end

          def toggle
            state[:values][name] = !value
          end
        end
      end
    end
  end
end
