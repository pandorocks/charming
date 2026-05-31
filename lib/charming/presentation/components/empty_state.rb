# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      class EmptyState < Component
        def initialize(message: "Nothing to show.", loading: false, loading_message: "Loading...", error: nil, error_message: nil, help: nil, theme: nil)
          super(theme: theme)
          @message = message
          @loading = loading
          @loading_message = loading_message
          @error = error
          @error_message = error_message
          @help = help
        end

        def render
          return loading_state if @loading
          return error_state if error?

          text @message, style: theme.muted
        end

        private

        def loading_state
          text @loading_message, style: theme.muted
        end

        def error_state
          lines = [text(@error_message || @error.to_s, style: theme.warn)]
          lines << text(@help, style: theme.muted) if @help.to_s.strip != ""

          column(*lines)
        end

        def error?
          @error.to_s.strip != "" || @error_message.to_s.strip != ""
        end
      end
    end
  end
end
