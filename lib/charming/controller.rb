# frozen_string_literal: true

module Charming
  class Controller
    class << self
      def key(name, action)
        key_bindings[name.to_s] = action
      end

      def command(label, action)
        command_bindings << Components::CommandPalette::Command.new(label: label, value: action)
      end

      def key_bindings
        @key_bindings ||= superclass.respond_to?(:key_bindings) ? superclass.key_bindings.dup : {}
      end

      def command_bindings
        @command_bindings ||= superclass.respond_to?(:command_bindings) ? superclass.command_bindings.dup : []
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
      return dispatch_command_palette_key if command_palette_open?

      action = self.class.key_bindings[key_name]
      action ? dispatch(action) : nil
    end

    def render(body = "")
      @response = Response.render(render_body(body))
    end

    def quit
      @response = Response.quit
    end

    def session
      application.session
    end

    def model(name, model_class, **attributes)
      session[:models] ||= {}
      session[:models][name.to_sym] ||= model_class.new(**attributes)
    end

    def open_command_palette
      session[:command_palette] = build_command_palette
      render_default_action
    end

    def close_command_palette
      session.delete(:command_palette)
      render_default_action
    end

    def command_palette_open?
      session.key?(:command_palette)
    end

    def command_palette
      session[:command_palette]
    end

    private

    attr_reader :response

    def render_body(body)
      body.respond_to?(:render) ? body.render.to_s : body.to_s
    end

    def key_name
      event.respond_to?(:key) ? event.key.to_s : event.to_s
    end

    def dispatch_command_palette_key
      result = command_palette.handle_key(event)
      close_command_palette if result == :cancelled
      perform_command(result.last) if selected_command?(result)
      render_default_action unless response
      response
    end

    def build_command_palette
      Components::CommandPalette.new(commands: self.class.command_bindings, height: 6)
    end

    def selected_command?(result)
      result.is_a?(Array) && result.first == :selected
    end

    def perform_command(command)
      send(command.value)
      close_command_palette unless command.value == :quit
    end

    def render_default_action
      show if respond_to?(:show)
    end
  end
end
