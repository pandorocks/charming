# frozen_string_literal: true

module Charming
  class Controller
    module SessionState
      def session
        application.session
      end

      def state(name, state_class, **attributes)
        session[:states] ||= {}
        session[:states][name.to_sym] ||= state_class.new(**attributes)
      end

      def form(name, &block)
        session[:forms] ||= {}
        form_state = session[:forms][name.to_sym] ||= {}
        builder = Presentation::Components::Form::Builder.new(theme: theme)
        block.arity.zero? ? builder.instance_eval(&block) : block.call(builder)
        builder.build(state: form_state, theme: theme)
      end

      def run_task(name, &block)
        application.task_executor.submit(name, &block)
      end
    end
  end
end
