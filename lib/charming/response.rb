# frozen_string_literal: true

module Charming
  # Response encapsulates a controller's dispatch outcome — one of render text, navigate to another route, or quit.
  # Rails-style factories (`render`, `navigate`, `quit`) serve as the public API and map to :kind values
  # that the Runtime interprets at the end of each event loop iteration.
  Response = Data.define(:kind, :body, :path) do
    # Factory constructing a Render response for displaying *body* text on the current screen.
    def self.render(body)
      new(kind: :render, body: body, path: nil)
    end

    # Factory constructing a NavigateResponse routing to the named *path* (string).
    def self.navigate(path)
      new(kind: :navigate, body: "", path: path)
    end

    # Factory constructing a QuitResponse signalling termination of the top-level event loop.
    def self.quit
      new(kind: :quit, body: "", path: nil)
    end

    # Returns `true` when this response is navigating to another screen or route.
    def navigate?
      kind == :navigate
    end

    # Returns `true` when this response requests quitting the application.
    def quit?
      kind == :quit
    end
  end
end
