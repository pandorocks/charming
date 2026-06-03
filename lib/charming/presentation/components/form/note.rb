# frozen_string_literal: true

module Charming
  module Components
    class Form
      # Note is a non-interactive Form field that renders a static string of text. Notes
      # never receive focus, never validate, and store no value — they are presentational
      # only, useful for headings, dividers, or instructional text inside a form.
      class Note < Field
        # *text* is the literal string to render. *name* is unused (defaults to :note) and
        # exists only because the Field base class requires a name.
        def initialize(text, name: :note, theme: nil)
          super(name, theme: theme)
          @text = text
        end

        # Binds the field to the form state but does not create any per-field storage.
        def bind(state)
          @state = state
        end

        # Notes are never focusable and therefore excluded from Tab/Enter traversal.
        def focusable?
          false
        end

        # Notes never produce validation errors.
        def validate
          []
        end

        # Returns the literal text, ignoring the *active:* flag (notes have no focus state).
        def render(active: false)
          @text.to_s
        end
      end
    end
  end
end
