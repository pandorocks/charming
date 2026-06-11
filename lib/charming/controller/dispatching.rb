# frozen_string_literal: true

module Charming
  class Controller
    # Key-dispatch helpers mixed into Controller. Resolves the current event's key symbol and
    # looks up bindings by scope (content vs. global) before they are sent to controller actions.
    module Dispatching
      private

      # Returns the normalized key symbol for the current controller event.
      def key_name
        Charming.key_of(event)
      end

      # Returns the normalized key signature for controller-declared bindings.
      def binding_key_name
        Charming.key_signature(event)
      end

      # Calls the auto-render action if one is configured. No-op when the action method is undefined.
      def render_default_action
        action = self.class.auto_render_action || :show
        public_send(action) if respond_to?(action)
      end

      # True when an explicit auto-render action is configured and the just-completed *action* is
      # not itself the auto-render action (to avoid infinite loops).
      def auto_render_after?(action)
        auto_render_action = self.class.auto_render_action
        auto_render_action && action.to_sym != auto_render_action
      end

      # Returns the action method bound to the current key at :global scope, or nil if none.
      def global_key_action
        key_action_for_scope(:global)
      end

      # Returns the action method bound to the current key at :content scope, or nil if the
      # content scope is not active (e.g., sidebar has focus).
      def content_key_action
        return nil unless content_key_scope_active?

        key_action_for_scope(:content)
      end

      # Returns false when the focus ring includes a content slot that isn't currently
      # focused (e.g., the sidebar has focus). Controllers whose ring has no :content slot
      # always have content keys active.
      def content_key_scope_active?
        return content_focused? if focus.ring.include?(:content)

        true
      end

      # Looks up the current key in the class bindings and returns the action only if its
      # registered scope matches *scope*. Returns nil otherwise.
      def key_action_for_scope(scope)
        action = self.class.key_bindings[binding_key_name]
        return nil unless action
        return nil unless self.class.key_binding_scopes.fetch(binding_key_name, :content) == scope

        action
      end
    end
  end
end
