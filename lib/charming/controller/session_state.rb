# frozen_string_literal: true

module Charming
  class Controller
    # Session-state helpers mixed into Controller: accessing the application session hash, lazy
    # state-object lookup by name/class, form builder invocation, and async task submission.
    module SessionState
      # Returns the application session hash for this controller. All persistent state (focus,
      # sidebar index, command palette, user state objects) lives here.
      def session
        application.session
      end

      # Returns the named session-backed state object, creating it on first access. *name* is a
      # symbol key under `session[:states]`. *state_class* is an ApplicationState subclass whose
      # constructor receives *attributes* on first creation. Subsequent calls return the same object.
      def state(name, state_class, **attributes)
        session[:states] ||= {}
        session[:states][name.to_sym] ||= state_class.new(**attributes)
      end

      # Builds a Form component scoped to the named form slot in `session[:forms]`. The block is
      # evaluated against a Form::Builder (or invoked with the builder as its argument for arity-1 blocks)
      # and returns a Form component pre-bound to the per-form mutable state hash.
      def form(name, &block)
        session[:forms] ||= {}
        form_state = session[:forms][name.to_sym] ||= {}
        builder = Presentation::Components::Form::Builder.new(theme: theme)
        block.arity.zero? ? builder.instance_eval(&block) : block.call(builder)
        builder.build(state: form_state, theme: theme)
      end

      # Submits a background task with the given *name*. The block is executed by the configured
      # task executor; its return value (or any raised exception) is delivered to the controller
      # as a TaskEvent dispatched to the matching `on_task` handler.
      def run_task(name, &block)
        application.task_executor.submit(name, &block)
      end
    end
  end
end
