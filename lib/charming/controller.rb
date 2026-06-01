# frozen_string_literal: true

module Charming
  # Controller is the base class for all controller implementations in a Charming application.
  # It provides the action dispatch pipeline, key/command/timer/task bindings, sidebar navigation,
  # command palette management, and view rendering with layout composition.
  class Controller
    TimerBinding = Data.define(:name, :interval, :action)
    TaskBinding = Data.define(:name, :action)

    extend ClassMethods
    include Rendering
    include SessionState
    include FocusManagement
    include SidebarNavigation
    include CommandPalette
    include ComponentDispatching
    include Dispatching

    attr_reader :application, :event, :params, :screen, :route

    # Initializes the controller with its parent application and optional event.
    # Defaults to an 80x24 screen when no backend size is available.
    def initialize(application:, event: nil, params: {}, screen: nil, route: nil)
      @application = application
      @event = event
      @params = params
      @screen = screen || Screen.new(width: 80, height: 24)
      @route = route
      @response = nil
    end

    # Dispatches a named action on this controller (e.g. :show).
    def dispatch(action)
      public_send(action)
      render_default_action if response.nil? && auto_render_after?(action)
      response || render("")
    end

    # Key event dispatch: checks command palette first, then global bindings,
    # sidebar (if focused), content bindings, tab traversal, and focused component.
    def dispatch_key
      return dispatch_command_palette_key if command_palette_open?
      return dispatch(global_key_action) if global_key_action
      return dispatch_sidebar_key if sidebar_focused?
      return dispatch(content_key_action) if content_key_action
      return response if dispatch_tab_traversal == :handled
      return response if dispatch_to_focused_component == :handled
      nil
    end

    # Timer event dispatcher: looks up the named action in timer bindings.
    def dispatch_timer
      b = self.class.timer_bindings[event.name.to_sym]
      return nil unless b

      public_send(b.action)
      response
    end

    # Task event dispatcher: looks up the handler in task bindings.
    def dispatch_task
      b = self.class.task_bindings[event.name.to_sym]
      b ? dispatch(b.action) : nil
    end

    # Mouse event dispatcher: checks command palette (if open), sidebar (if focused).
    def dispatch_mouse
      return dispatch_command_palette_mouse if command_palette_open?
      return dispatch_sidebar_mouse if sidebar_focused?
      dispatch_component_mouse
    end

    # Renders a body or template wrapped in the controller's layout.
    def render(body = "", **assigns)
      body = view_body(default_template_name(body), **assigns) if body.is_a?(Symbol)
      @response = Response.render(render_with_layout(body))
    end

    def render_view(view_class, **assigns)
      @response = Response.render(render_with_layout(view_class.new(**template_assigns(assigns))))
    end

    def render_template(name, **assigns)
      @response = Response.render(render_with_layout(template_body(name, **assigns)))
    end

    def theme
      application.theme
    end

    def use_theme(name)
      application.use_theme(name)
    end

    def open_theme_palette
      session[:command_palette] = command_palette_state(:themes)
      focus.push_scope([:command_palette], origin: :command_palette)
      render_default_action
    end

    # Navigates to the given URL path.
    def navigate_to(path)
      @response = Response.navigate(path)
    end

    # Exits the application — sets a quit response that terminates the event loop.
    def quit
      @response = Response.quit
    end

    private

    attr_reader :response
  end
end
