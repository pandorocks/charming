# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      # EmptyState is a placeholder component for screens with no content. Renders one of three
      # states: a default "nothing to show" message, a "loading…" message, or an error message
      # with optional help text.
      class EmptyState < Component
        # *message* is shown in the default state. *loading* switches to the loading message
        # (overrides *message*). *loading_message* is the string rendered in the loading state.
        # *error* and *error_message* switch to the error state (the string form takes precedence).
        # *help* is an optional muted line shown below the error message.
        def initialize(message: "Nothing to show.", loading: false, loading_message: "Loading...", error: nil, error_message: nil, help: nil, theme: nil)
          super(theme: theme)
          @message = message
          @loading = loading
          @loading_message = loading_message
          @error = error
          @error_message = error_message
          @help = help
        end

        # Renders the appropriate state as styled text: loading → loading message, error →
        # error message + help, otherwise the default message.
        def render
          return loading_state if @loading
          return error_state if error?

          text @message, style: theme.muted
        end

        private

        # Renders the loading state as a muted line.
        def loading_state
          text @loading_message, style: theme.muted
        end

        # Renders the error state: the error message styled with the theme's warn style,
        # optionally followed by a muted help line.
        def error_state
          lines = [text(@error_message || @error.to_s, style: theme.warn)]
          lines << text(@help, style: theme.muted) if @help.to_s.strip != ""

          column(*lines)
        end

        # True when either the *error* or *error_message* string is non-blank.
        def error?
          @error.to_s.strip != "" || @error_message.to_s.strip != ""
        end
      end
    end
  end
end
