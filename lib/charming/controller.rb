# frozen_string_literal: true

module Charming
  # Controller is the base class for all controller implementations in a Charming application.
  # It provides the action dispatch pipeline, key/command/timer/task bindings, sidebar navigation,
  # command palette management, and view rendering with layout composition.
  class Controller
    TimerBinding = Data.define(:name, :interval, :action)
    TaskBinding = Data.define(:name, :action)

    extend ClassMethods
    include ActionHooks
    include Rendering
    include SessionState
    include FocusManagement
    include SidebarNavigation
    include CommandPalette
    include ComponentDispatching
    include Dispatching
    include Terminal

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

    # Dispatches a named action on this controller (e.g. :show), running all
    # before/around/after hooks and rescue_from handlers.
    def dispatch(action)
      run_action_with_hooks(action)
      render_default_action if response.nil? && auto_render_after?(action)
      response || render("")
    end

    # Key event dispatch, in priority order:
    # 1. Command palette (when open) consumes everything.
    # 2. A focused text-capturing component (TextInput, TextArea, Form, …) gets
    #    printable characters BEFORE key bindings — typing "q" into a field must
    #    insert a q, not quit the app.
    # 3. Global key bindings.
    # 4. An overlay focus scope (a pushed modal) captures all remaining keys.
    # 5. Sidebar keys (when focused), content bindings, then the focused component —
    #    which sees Tab before ring traversal so forms can do field navigation.
    def dispatch_key
      return dispatch_command_palette_key if command_palette_open?

      if printable_text_event? && focused_component_captures_text?
        return response if dispatch_to_focused_component == :handled
      end

      return dispatch(global_key_action) if global_key_action

      if focus.overlay?
        dispatch_to_focused_component
        return response
      end

      return dispatch_sidebar_key if sidebar_focused?
      return dispatch(content_key_action) if content_key_action

      # Text-capturing components (forms, editors) own their remaining keys — Tab
      # included, so forms do field navigation. Everything else keeps ring traversal
      # ahead of the component.
      if focused_component_captures_text?
        return response if dispatch_to_focused_component == :handled
        return response if dispatch_tab_traversal == :handled
      else
        return response if dispatch_tab_traversal == :handled
        return response if dispatch_to_focused_component == :handled
      end
      nil
    end

    # Timer event dispatcher: looks up the named action in timer bindings and runs it
    # with the full hook chain. Unlike #dispatch there is no render("") fallback — a
    # timer action that renders nothing yields a nil response, so silent ticks skip
    # the repaint instead of blanking the screen.
    def dispatch_timer
      b = self.class.timer_bindings[event.name.to_sym]
      return nil unless b

      run_action_with_hooks(b.action)
      response
    end

    # Task event dispatcher: looks up the handler in task bindings.
    def dispatch_task
      b = self.class.task_bindings[event.name.to_sym]
      b ? dispatch(b.action) : nil
    end

    # Task progress dispatcher: looks up the handler in task progress bindings.
    def dispatch_task_progress
      b = self.class.task_progress_bindings[event.name.to_sym]
      b ? dispatch(b.action) : nil
    end

    # Paste event dispatcher: forwards pasted text to the focused component's
    # `handle_paste` (TextInput, TextArea, and form fields support it).
    def dispatch_paste
      slot = focus.current
      return nil unless slot && respond_to?(slot, true)

      component = send(slot)
      return nil unless component.respond_to?(:handle_paste)

      result = component.handle_paste(event)
      return nil if result.nil?

      dispatch_component_result(slot, result)
      response
    end

    # Mouse event dispatcher: command palette (if open) wins, then sidebar clicks
    # (route rows navigate directly), then named layout panes/components.
    def dispatch_mouse
      return dispatch_command_palette_mouse if command_palette_open?

      sidebar_response = dispatch_sidebar_mouse
      return sidebar_response if sidebar_response

      dispatch_component_mouse
    end

    # Renders a body or template wrapped in the controller's layout. Out-of-band escape sequences
    # registered while rendering (e.g. image transmissions) are collected by the Runtime around the
    # whole dispatch and attached to the response.
    def render(body = "", **assigns)
      body = view_body(default_template_name(body), **assigns) if body.is_a?(Symbol)
      @response = Response.render(render_with_layout(body))
    end

    def render_view(view_class, **assigns)
      @response = Response.render(render_with_layout(view_class.new(**template_assigns(assigns))))
    end

    # Renders a template from `app/views` by name, applying the controller's layout. *name* is the
    # template path (e.g., "home/show") and additional keyword *assigns* are forwarded to the view.
    def render_template(name, **assigns)
      @response = Response.render(render_with_layout(template_body(name, **assigns)))
    end

    # Returns the active theme for this request, delegated to the application.
    def theme
      application.theme
    end

    # Switches the active theme to *name* and persists the choice in the application session.
    def use_theme(name)
      application.use_theme(name)
    end

    # Returns the application logger. The default logger writes to File::NULL, so logging calls are
    # safe in TUI code unless the app explicitly configures a file or custom logger.
    def logger
      application.logger
    end

    # Opens the theme picker (a CommandPalette populated with the registered themes) and renders.
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
