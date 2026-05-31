# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Builder
          attr_reader :fields, :theme

          def initialize(theme: nil)
            @theme = theme
            @fields = []
          end

          def input(name, **options)
            fields << Input.new(name, **field_options(options))
          end

          def textarea(name, **options)
            fields << Textarea.new(name, **field_options(options))
          end

          def select(name, **options)
            fields << Select.new(name, **field_options(options))
          end

          def confirm(name, **options)
            fields << Confirm.new(name, **field_options(options))
          end

          def note(text, **options)
            fields << Note.new(text, **field_options(options))
          end

          def build(state:, theme: nil)
            Components::Form.new(fields: fields, state: state, theme: theme || self.theme)
          end

          private

          def field_options(options)
            {theme: theme}.merge(options)
          end
        end
      end
    end
  end
end
