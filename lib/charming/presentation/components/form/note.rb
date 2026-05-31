# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class Form
        class Note < Field
          def initialize(text, name: :note, theme: nil)
            super(name, theme: theme)
            @text = text
          end

          def bind(state)
            @state = state
          end

          def focusable?
            false
          end

          def validate
            []
          end

          def render(active: false)
            @text.to_s
          end
        end
      end
    end
  end
end
