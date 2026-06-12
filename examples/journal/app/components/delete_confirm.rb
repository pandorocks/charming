# frozen_string_literal: true

module Journal
  # DeleteConfirm is a modal that captures all keys while open: y confirms
  # ([:submitted, true]), n/escape cancels (:cancelled), anything else is swallowed.
  class DeleteConfirm < Charming::Component
    def initialize(entry_title:, theme: nil)
      super(theme: theme)
      @entry_title = entry_title
    end

    def handle_key(event)
      case Charming.key_of(event)
      when :y then [:submitted, true]
      when :n, :escape then :cancelled
      else :handled
      end
    end

    def render
      render_component(
        Charming::Components::Modal.new(
          content: "Delete \"#{@entry_title}\"?\n\nThis cannot be undone.",
          title: "Delete entry",
          help: "y deletes · n or esc cancels",
          width: 46,
          theme: theme
        )
      )
    end
  end
end
