# frozen_string_literal: true

module Charming
  module Components
    # KeyboardHandler is a mixin module that provides keyboard event dispatch by mapping symbolic key names
    # to private method calls. Implementors must define a constant +KEY_ACTIONS+ as a hash where each key is
    # a symbol (e.g., :up, :down, :enter) and each value is the target method name (e.g., :move_up). Call
    # +handle_key(event)+ with any event object; it uses Charming.key_of to resolve the raw event to a symbol,
    # looks up the corresponding action in KEY_ACTIONS, sends that method on self, and returns :handled if an
    # action was found. Returns nil (via :handled being truthy or not) when no matching key exists.
    module KeyboardHandler
      def handle_key(event)
        key = Charming.key_of(event)
        action = self.class.const_get(:KEY_ACTIONS)[key]
        return unless action

        send(action)
        :handled
      end
    end
  end
end
