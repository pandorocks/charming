# frozen_string_literal: true

module Charming
  module Components
    module KeyboardHandler
      def handle_key(event)
        key = Charming.key_of(event)
        action = self.class.const_get(:KEY_ACTIONS)[key.to_sym]
        return unless action

        send(action)
        :handled
      end
    end
  end
end
