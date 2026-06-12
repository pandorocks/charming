# frozen_string_literal: true

module Charming
  # Component is the base class for all reusable terminal widgets. It inherits from View to gain assigns,
  # helper methods (text, box, row, column, etc.), and rendering via render.
  class Component < View
    # True for components that accept free-typed text (TextInput, TextArea, Form, …).
    # While such a component is focused, the controller routes printable characters to
    # it BEFORE global/content key bindings — so typing "q" or "?" into a field inserts
    # the character instead of triggering an app shortcut.
    def captures_text?
      false
    end
  end
end
