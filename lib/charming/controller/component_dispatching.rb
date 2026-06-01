# frozen_string_literal: true

module Charming
  class Controller
    module ComponentDispatching
      private

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

      def dispatch_component_result(slot, result)
        action, arguments = component_result_action(slot, result)
        action ? send(action, *arguments) : render_default_action
        render_default_action unless response
      end

      def component_result_action(slot, result)
        case result
        when :cancelled
          component_action(slot, :cancelled)
        when Array
          component_array_action(slot, result)
        end
      end

      def component_array_action(slot, result)
        event_name, value = result
        return component_action(slot, :submitted, value) if event_name == :submitted
        return component_action(slot, :selected, value) if event_name == :selected

        nil
      end

      def component_action(slot, suffix, *arguments)
        action = :"#{slot}_#{suffix}"
        return unless respond_to?(action, true)

        [action, arguments]
      end

      def dispatch_tab_traversal
        return nil unless key_name == :tab
        return nil if focus.ring.empty?

        focus.cycle(event.shift ? -1 : +1)
        render_default_action
        :handled
      end

      def dispatch_component_mouse
        nil
      end
    end
  end
end
