# frozen_string_literal: true

module Charming
  class Controller
    # Component-dispatch helpers mixed into Controller. Forwards key events to the currently
    # focused component (the slot returned by `focus.current`) and translates component return
    # values into controller hook calls (e.g., `slot_submitted`, `slot_selected`, `slot_cancelled`).
    module ComponentDispatching
      private

      # Sends the current key event to the focused component (if it responds to `handle_key`).
      # Returns `:handled` after dispatching, or nil when no component is focused.
      def dispatch_to_focused_component
        slot = focus.current
        return nil unless slot && respond_to?(slot, true)

        component = send(slot)
        return nil unless component.respond_to?(:handle_key)

        result = component.handle_key(event)
        return nil if result.nil?

        dispatch_component_result(slot, result)
        :handled
      end

      # Translates a component `handle_key` *result* into a controller hook call. `:cancelled`
      # triggers `<slot>_cancelled`, `[:submitted, value]` triggers `<slot>_submitted(value)`,
      # `[:selected, value]` triggers `<slot>_selected(value)`. Falls back to a default render
      # when no matching hook exists.
      def dispatch_component_result(slot, result)
        action, arguments = component_result_action(slot, result)
        action ? send(action, *arguments) : render_default_action
        render_default_action unless response
      end

      # Resolves which controller hook (if any) corresponds to the *result* from a component.
      def component_result_action(slot, result)
        case result
        when :cancelled
          component_action(slot, :cancelled)
        when Array
          component_array_action(slot, result)
        end
      end

      # Handles array-shaped component results, currently `[:submitted, value]` and `[:selected, value]`.
      def component_array_action(slot, result)
        event_name, value = result
        return component_action(slot, :submitted, value) if event_name == :submitted
        return component_action(slot, :selected, value) if event_name == :selected

        nil
      end

      # Returns `[action, arguments]` for the `<slot>_<suffix>` controller hook if defined, or nil.
      def component_action(slot, suffix, *arguments)
        action = :"#{slot}_#{suffix}"
        return unless respond_to?(action, true)

        [action, arguments]
      end

      # Handles Tab/Shift+Tab by cycling through the focus ring. Returns :handled after rendering.
      def dispatch_tab_traversal
        return nil unless key_name == :tab
        return nil if focus.ring.empty?

        focus.cycle(event.shift ? -1 : +1)
        render_default_action
        :handled
      end

      # Default mouse dispatch hook: subclasses/components may override by including their own
      # mouse logic via the controller's `dispatch_component_mouse` override.
      def dispatch_component_mouse
        nil
      end
    end
  end
end
