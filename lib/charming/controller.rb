# frozen_string_literal: true

module Charming
  class Controller
    class << self
      def key(name, action)
        key_bindings[name.to_s] = action
      end

      def key_bindings
        @key_bindings ||= superclass.respond_to?(:key_bindings) ? superclass.key_bindings.dup : {}
      end
    end

    attr_reader :application, :event, :params

    def initialize(application:, event: nil, params: {})
      @application = application
      @event = event
      @params = params
      @response = nil
    end

    def dispatch(action)
      public_send(action)
      response || render("")
    end

    def dispatch_key
      action = self.class.key_bindings[key_name]
      action ? dispatch(action) : nil
    end

    def render(body = "")
      @response = Response.render(body.to_s)
    end

    def quit
      @response = Response.quit
    end

    def session
      application.session
    end

    private

    attr_reader :response

    def key_name
      event.respond_to?(:key) ? event.key.to_s : event.to_s
    end
  end
end
