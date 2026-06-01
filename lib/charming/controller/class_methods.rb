# frozen_string_literal: true

module Charming
  class Controller
    module ClassMethods
      def key(name, action, scope: :content)
        normalized_scope = validate_key_scope(scope)
        key_name = name.to_sym
        key_bindings[key_name] = action
        key_binding_scopes[key_name] = normalized_scope
      end

      def command(label, action = nil, &block)
        command_bindings << Presentation::Components::CommandPalette::Command.new(label: label, value: block || action)
      end

      def timer(name, every:, action:)
        timer_bindings[name.to_sym] = TimerBinding.new(name: name.to_sym, interval: every, action: action)
      end

      def on_task(name, action:)
        task_bindings[name.to_sym] = TaskBinding.new(name: name.to_sym, action: action)
      end

      def auto_render(action = :show)
        @auto_render_action = action.to_sym
      end

      def auto_render_action
        return @auto_render_action if instance_variable_defined?(:@auto_render_action)
        return superclass.auto_render_action if superclass.respond_to?(:auto_render_action)

        nil
      end

      def layout(layout_class = :__charming_layout_reader__)
        return resolved_layout if layout_class == :__charming_layout_reader__

        @layout = layout_class
      end

      def key_bindings
        @key_bindings ||= superclass.respond_to?(:key_bindings) ? superclass.key_bindings.dup : {}
      end

      def key_binding_scopes
        @key_binding_scopes ||= superclass.respond_to?(:key_binding_scopes) ? superclass.key_binding_scopes.dup : {}
      end

      def focus_ring(*slots)
        @focus_ring_slots = slots
      end

      def focus_ring_slots
        @focus_ring_slots ||= superclass.respond_to?(:focus_ring_slots) ? superclass.focus_ring_slots.dup : []
      end

      def command_bindings
        @command_bindings ||= superclass.respond_to?(:command_bindings) ? superclass.command_bindings.dup : []
      end

      def timer_bindings
        @timer_bindings ||= superclass.respond_to?(:timer_bindings) ? superclass.timer_bindings.dup : {}
      end

      def task_bindings
        @task_bindings ||= superclass.respond_to?(:task_bindings) ? superclass.task_bindings.dup : {}
      end

      private

      def validate_key_scope(scope)
        normalized_scope = scope.to_sym
        return normalized_scope if %i[content global].include?(normalized_scope)

        raise ArgumentError, "unknown key scope: #{scope.inspect}"
      end

      def resolved_layout
        return @layout if instance_variable_defined?(:@layout)
        return superclass.layout if superclass.respond_to?(:layout)

        nil
      end
    end
  end
end
