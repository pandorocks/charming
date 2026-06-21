# frozen_string_literal: true

module Charming
  class Controller
    # Terminal mixes imperative out-of-band terminal effects into Controller: writing the system
    # clipboard, raising desktop notifications, ringing the bell, and setting the window title. Each
    # registers an {Charming::Escape} sequence onto the dispatch's collection; the Runtime flushes it
    # to the backend before the next frame. They compose freely with a normal `render` — e.g.
    # `def copy_url; copy(state.url); notify("Copied!"); render(:show); end`.
    module Terminal
      # Writes *text* to the system clipboard (OSC 52). *target* selects the selection (`"c"`
      # clipboard, `"p"` primary). Works across Ghostty/Kitty/iTerm2 (and tmux with passthrough).
      def copy(text, target: "c")
        Escape.register(Escape.clipboard(text, target: target))
      end

      # Raises a desktop notification showing *body* (and *title* when given).
      def notify(body, title: nil)
        Escape.register(Escape.notification(body, title: title))
      end

      # Rings the terminal bell.
      def bell
        Escape.register(Escape.bell)
      end

      # Sets the terminal window/tab title to *text* (OSC 0).
      def set_title(text)
        Escape.register(Escape.title(text))
      end
    end
  end
end
