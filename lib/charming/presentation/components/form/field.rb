# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Field < Component
          attr_reader :name, :label, :help, :state

          def initialize(name, label: nil, required: false, validate: nil, help: nil, theme: nil)
            super(theme: theme)
            @name = name.to_sym
            @label = label || humanize(name)
            @required = required
            @validator = validate
            @help = help
          end

          def bind(state)
            @state = state
            state[:fields][name] ||= {}
            state[:values][name] = default_value unless state[:values].key?(name)
          end

          def focusable?
            true
          end

          def handle_key(_event)
            nil
          end

          def render(active: false)
            line = "#{active ? ">" : " "} #{render_control}"
            line = theme.selected.render(line) if active
            [line, help_line, *error_lines].compact.join("\n")
          end

          def validate
            messages = []
            messages << "is required" if required? && blank?(value)
            messages.concat(validator_messages) if @validator
            messages
          end

          def value
            state[:values][name]
          end

          private

          def default_value
            nil
          end

          def render_control
            "#{label}: #{value}"
          end

          def required?
            @required
          end

          def blank?(value)
            return true if value.nil?
            return value.strip.empty? if value.is_a?(String)

            value.respond_to?(:empty?) && value.empty?
          end

          def validator_messages
            result = @validator.call(value)
            case result
            when nil, true then []
            when false then ["is invalid"]
            when Array then result
            else [result.to_s]
            end
          end

          def help_line
            "  #{theme.muted.render(help)}" if help
          end

          def error_lines
            Array(state[:errors][name]).map { |message| "  #{theme.warn.render(message)}" }
          end

          def humanize(value)
            value.to_s.tr("_", " ").capitalize
          end
        end
      end
    end
  end
end
