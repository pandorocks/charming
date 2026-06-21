# frozen_string_literal: true

module Charming
  # Response encapsulates a controller's dispatch outcome — one of render text, navigate to another route, or quit.
  # Rails-style factories (`render`, `navigate`, `quit`) serve as the public API and map to :kind values
  # that the Runtime interprets at the end of each event loop iteration.
  #
  # *escapes* carries any out-of-band terminal sequences (image transmissions, clipboard writes,
  # notifications, window-title changes) gathered during the dispatch. The Runtime flushes them straight
  # to the backend, bypassing the line-based frame pipeline. It is empty for ordinary responses.
  Response = Data.define(:kind, :body, :path, :escapes) do
    # Factory constructing a Render response for displaying *body* text on the current screen. *escapes*
    # is the list of out-of-band sequences gathered during the dispatch (defaults to none).
    def self.render(body, escapes: [])
      new(kind: :render, body: body, path: nil, escapes: escapes)
    end

    # Factory constructing a NavigateResponse routing to the named *path* (string).
    def self.navigate(path)
      new(kind: :navigate, body: "", path: path, escapes: [])
    end

    # Factory constructing a QuitResponse signalling termination of the top-level event loop.
    def self.quit
      new(kind: :quit, body: "", path: nil, escapes: [])
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
