# frozen_string_literal: true

module Charming
  class Controller
    module Dispatching
      private

      def key_name
        Charming.key_of(event)
      end

      def render_default_action
        action = self.class.auto_render_action || :show
        public_send(action) if respond_to?(action)
      end

      def auto_render_after?(action)
        auto_render_action = self.class.auto_render_action
        auto_render_action && action.to_sym != auto_render_action
      end

      def global_key_action
        key_action_for_scope(:global)
      end

      def content_key_action
        return nil unless content_key_scope_active?

        key_action_for_scope(:content)
      end

      def content_key_scope_active?
        return content_focused? if focus_ring_slot?(:content)

        true
      end

      def key_action_for_scope(scope)
        action = self.class.key_bindings[key_name]
        return nil unless action
        return nil unless self.class.key_binding_scopes.fetch(key_name, :content) == scope

        action
      end
    end
  end
end
