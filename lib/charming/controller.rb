# frozen_string_literal: true

module Charming
  class Controller
    TimerBinding = Data.define(:name, :interval, :action)

    class << self
      def key(name, action)
        key_bindings[name.to_s] = action
      end

      def command(label, action = nil, &block)
        command_bindings << Components::CommandPalette::Command.new(label: label, value: block || action)
      end

      def timer(name, every:, action:)
        timer_bindings[name.to_sym] = TimerBinding.new(name: name.to_sym, interval: every, action: action)
      end

      def layout(layout_class = :__charming_layout_reader__)
        return resolved_layout if layout_class == :__charming_layout_reader__

        @layout = layout_class
      end

      def key_bindings
        @key_bindings ||= superclass.respond_to?(:key_bindings) ? superclass.key_bindings.dup : {}
      end

      def command_bindings
        @command_bindings ||= superclass.respond_to?(:command_bindings) ? superclass.command_bindings.dup : []
      end

      def timer_bindings
        @timer_bindings ||= superclass.respond_to?(:timer_bindings) ? superclass.timer_bindings.dup : {}
      end

      private

      def resolved_layout
        return @layout if instance_variable_defined?(:@layout)
        return superclass.layout if superclass.respond_to?(:layout)

        nil
      end
    end

    attr_reader :application, :event, :params, :screen

    def initialize(application:, event: nil, params: {}, screen: nil)
      @application = application
      @event = event
      @params = params
      @screen = screen || Screen.new(width: 80, height: 24)
      @response = nil
    end

    def dispatch(action)
      public_send(action)
      response || render("")
    end

    def dispatch_key
      return dispatch_command_palette_key if command_palette_open?
      return dispatch_sidebar_key if sidebar_focused?

      action = self.class.key_bindings[key_name]
      action ? dispatch(action) : nil
    end

    def dispatch_timer
      binding = self.class.timer_bindings[event.name.to_sym]
      binding ? dispatch(binding.action) : nil
    end

    def dispatch_mouse
      return dispatch_command_palette_mouse if command_palette_open?
      return dispatch_sidebar_mouse if sidebar_focused?

      dispatch_component_mouse
    end

    def render(body = "")
      @response = Response.render(render_with_layout(body))
    end

    def navigate_to(path)
      @response = Response.navigate(path)
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

    def focus_sidebar
      session[:focus] = :sidebar
      session[:sidebar_index] ||= current_route_index
      render_default_action
    end

    def focus_content
      session[:focus] = :content
      render_default_action
    end

    def sidebar_focused?
      session[:focus] == :sidebar
    end

    def sidebar_index
      session[:sidebar_index] || current_route_index
    end

    private

    def current_route_index
      application.routes.all.index { |route| route.controller_class == self.class && route.action == :show } || 0
    end

    attr_reader :response

    def render_body(body)
      body.respond_to?(:render) ? body.render.to_s : body.to_s
    end

    def render_with_layout(body)
      rendered = render_body(body)
      layout_class = self.class.layout
      return rendered unless layout_class

      render_body(layout_class.new(**layout_assigns(body, rendered)))
    end

    def layout_assigns(body, rendered)
      view_assigns(body).merge(content: rendered, screen: screen, controller: self)
    end

    def view_assigns(body)
      body.respond_to?(:layout_assigns) ? body.layout_assigns : {}
    end

    def key_name
      Charming.key_of(event).to_s
    end

    def dispatch_command_palette_key
      result = command_palette.handle_key(event)
      close_command_palette if result == :cancelled
      perform_command(result.last) if selected_command?(result)
      render_default_action unless response
      response
    end

    def dispatch_command_palette_mouse
      nil
    end

    def dispatch_sidebar_key
      case key_name
      when "j", "down" then sidebar_move(+1)
      when "k", "up"   then sidebar_move(-1)
      when "enter"     then sidebar_select
      when "escape", "tab" then focus_content
      else render_default_action
      end
      response
    end

    def dispatch_component_mouse
      nil
    end

    def sidebar_move(delta)
      count = application.routes.all.length
      return render_default_action if count.zero?

      session[:sidebar_index] = (sidebar_index + delta).clamp(0, count - 1)
      render_default_action
    end

    def sidebar_select
      route = application.routes.all[sidebar_index]
      session[:focus] = :content
      route ? navigate_to(route.path) : render_default_action
    end

    def build_command_palette
      Components::CommandPalette.new(commands: self.class.command_bindings, height: 6)
    end

    def selected_command?(result)
      result.is_a?(Array) && result.first == :selected
    end

    def perform_command(command)
      perform_command_value(command.value)
      session.delete(:command_palette) unless command.value == :quit
      render_default_action unless response&.navigate? || response&.quit?
    end

    def perform_command_value(value)
      value.respond_to?(:call) ? instance_exec(&value) : send(value)
    end

    def render_default_action
      show if respond_to?(:show)
    end
  end
end
