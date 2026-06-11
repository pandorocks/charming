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

      # Stores the named layout panes from the latest render so mouse events can be hit-tested
      # against the same focus slots used by Tab traversal.
      def register_mouse_targets(targets)
        session[:mouse_targets] = targets
      end

      # Returns the named layout panes from the latest render.
      def mouse_targets
        session.fetch(:mouse_targets, [])
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
        builder = Components::Form::Builder.new(theme: theme)
        block.arity.zero? ? builder.instance_eval(&block) : block.call(builder)
        builder.build(state: form_state, theme: theme)
      end

      # Submits a background task with the given *name*. The block is executed by the configured
      # task executor; its return value (or any raised exception) is delivered to the controller
      # as a TaskEvent dispatched to the matching `on_task` handler.
      #
      # Blocks that accept an argument receive a Tasks::Progress reporter whose `report`
      # calls dispatch the matching `on_task_progress` handler. *timeout:* (seconds)
      # cancels the task with Tasks::Cancelled when exceeded.
      def run_task(name, timeout: nil, &block)
        return application.task_executor.submit(name, timeout: timeout, &block) if timeout

        # Without a timeout, use the plain signature so simple custom executors
        # (`def submit(name, &block)`) remain compatible.
        application.task_executor.submit(name, &block)
      end

      # Cancels the named in-flight background task (raises Tasks::Cancelled inside it).
      # No-op when the task already finished or the executor doesn't support cancellation.
      def cancel_task(name)
        executor = application.task_executor
        executor.cancel(name) if executor.respond_to?(:cancel)
      end
    end
  end
end
