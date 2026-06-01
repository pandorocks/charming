# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        # Builder collects form field declarations inside a `form(:name) { ... }` block and
        # assembles them into a Form component when `build` is called. Each declaration method
        # appends a Field subclass instance to the builder's *fields* list.
        class Builder
          # The accumulated field list and the theme applied to each declared field.
          attr_reader :fields, :theme

          # Initializes an empty builder. *theme* is forwarded to every declared field unless
          # the field declaration explicitly overrides it.
          def initialize(theme: nil)
            @theme = theme
            @fields = []
          end

          # Appends a single-line Input field. *options* are passed through to Input.
          def input(name, **options)
            fields << Input.new(name, **field_options(options))
          end

          # Appends a multi-line Textarea field.
          def textarea(name, **options)
            fields << Textarea.new(name, **field_options(options))
          end

          # Appends a Select field with the given *options* array.
          def select(name, **options)
            fields << Select.new(name, **field_options(options))
          end

          # Appends a Confirm (boolean) field.
          def confirm(name, **options)
            fields << Confirm.new(name, **field_options(options))
          end

          # Appends a static Note (non-focusable).
          def note(text, **options)
            fields << Note.new(text, **field_options(options))
          end

          # Assembles the collected fields into a Form component, bound to *state* and using
          # the *theme* argument (falling back to the builder's theme).
          def build(state:, theme: nil)
            Components::Form.new(fields: fields, state: state, theme: theme || self.theme)
          end

          private

          # Merges the builder's theme into the per-field *options* so each field receives it.
          def field_options(options)
            {theme: theme}.merge(options)
          end
        end
      end
    end
  end
end
