# frozen_string_literal: true

module Charming
  # Controller is the base class for all controller implementations in a Charming application.
  # It provides the action dispatch pipeline, key/command/timer/task bindings, sidebar navigation,
  # command palette management, and view rendering with layout composition.
  class Controller
    TimerBinding = Data.define(:name, :interval, :action)
    TaskBinding = Data.define(:name, :action)

    class << self
      # Registers a key binding (string or symbol key name → method symbol).
      # When the event loop reads this key, it calls the corresponding controller action.
      def key(name, action)
        key_bindings[name.to_s] = action
      end

      # Registers a command palette entry — visible in fuzzy search when Ctrl+K is pressed.
      # Accepts either a method symbol or an inline callable block.
      def command(label, action = nil, &block)
        command_bindings << Components::CommandPalette::Command.new(label: label, value: block || action)
      end

      # Registers a periodic timer that fires at `every`-second intervals.
      # The named action is dispatched on the current route's controller each time.
      def timer(name, every:, action:)
        timer_bindings[name.to_sym] = TimerBinding.new(name: name.to_sym, interval: every, action: action)
      end

      # Registers an async task handler that runs when a TaskEvent arrives from the task executor.
      def on_task(name, action:)
        task_bindings[name.to_sym] = TaskBinding.new(name: name.to_sym, action: action)
      end

      # Sets the layout class to wrap this controller's rendered output (e.g., for sidebar + main content).
      # Accepts a special `:__charming_layout_reader__` sentinel to query — without setting — the current layout.
      def layout(layout_class = :__charming_layout_reader__)
        return resolved_layout if layout_class == :__charming_layout_reader__

        @layout = layout_class
      end

      # Returns inherited key bindings merged from the class hierarchy.
      # Each subclass gets a fresh copy of its parent's key bindings to avoid cross-controller pollution.
      def key_bindings
        @key_bindings ||= superclass.respond_to?(:key_bindings) ? superclass.key_bindings.dup : {}
      end

      # Registers a focus ring slot for this controller — slots participate in Tab/Shift+Tab traversal.
      # Example: `focus_ring :sidebar, :content` makes sidebar and content tabbable.
      def focus_ring(*slots)
        @focus_ring_slots = slots
      end

      # Returns inherited focus ring slots merged from the class hierarchy.
      def focus_ring_slots
        @focus_ring_slots ||= superclass.respond_to?(:focus_ring_slots) ? superclass.focus_ring_slots.dup : []
      end

      # Returns inherited command bindings (command palette entries) from this controller and its ancestors.
      def command_bindings
        @command_bindings ||= superclass.respond_to?(:command_bindings) ? superclass.command_bindings.dup : []
      end

      # Returns inherited timer bindings from this controller and its ancestors.
      def timer_bindings
        @timer_bindings ||= superclass.respond_to?(:timer_bindings) ? superclass.timer_bindings.dup : {}
      end

      # Returns inherited task bindings (async task handlers) from this controller and its ancestors.
      def task_bindings
        @task_bindings ||= superclass.respond_to?(:task_bindings) ? superclass.task_bindings.dup : {}
      end

      private

      # Returns the layout class for this controller, walking up the inheritance chain until one is found or nil.
      # Used internally by `layout` when called without args (getter mode).
      def resolved_layout
        return @layout if instance_variable_defined?(:@layout)
        return superclass.layout if superclass.respond_to?(:layout)

        nil
      end
    end

    attr_reader :application, :event, :params, :screen

    # Initializes the controller with its parent application and an optional event (key/mouse/timer/task data).
    # Defaults to a 80x24 screen when no backend size is available.
    def initialize(application:, event: nil, params: {}, screen: nil)
      @application = application
      @event = event
      @params = params
      @screen = screen || Screen.new(width: 80, height: 24)
      @response = nil
    end

    # Dispatches a named action on this controller (e.g., :show). Calls the method via public_send,
    # returning a default empty render if the action produces no response.
    def dispatch(action)
      public_send(action)
      response || render("")
    end

    # Key event dispatch pipeline for controllers: checks command palette first (if open),
    # then sidebar (if focused), then registered key bindings, then tab traversal,
    # then focused component handling. Returns nil if no handler consumed the event.
    def dispatch_key
      return dispatch_command_palette_key if command_palette_open?
      return dispatch_sidebar_key if sidebar_focused?

      action = self.class.key_bindings[key_name]
      return dispatch(action) if action
      return response if dispatch_tab_traversal == :handled
      return response if dispatch_to_focused_component == :handled

      nil
    end

    # Timer event dispatcher: looks up the event's named action in this controller's timer bindings
    # and dispatches it. Returns nil if no binding exists for this timer name.
    def dispatch_timer
      binding = self.class.timer_bindings[event.name.to_sym]
      binding ? dispatch(binding.action) : nil
    end

    # Task event dispatcher: looks up the event's named handler in this controller's task bindings
    # and dispatches it. Used by async tasks submitted via `run_task`.
    def dispatch_task
      binding = self.class.task_bindings[event.name.to_sym]
      binding ? dispatch(binding.action) : nil
    end

    # Mouse event dispatcher: checks command palette (if open), then sidebar (if focused),
    # then falls through to component mouse dispatch. Always returns nil in the base controller —
    # subclasses override as needed.
    def dispatch_mouse
      return dispatch_command_palette_mouse if command_palette_open?
      return dispatch_sidebar_mouse if sidebar_focused?

      dispatch_component_mouse
    end

    # Renders `body` wrapped in this controller's layout (if one is defined) and stores the response.
    # If no layout is set, renders body bare. Called by controllers after rendering a view.
    def render(body = "")
      @response = Response.render(render_with_layout(body))
    end

    def theme
      application.theme
    end

    def use_theme(name)
      application.use_theme(name)
    end

    def open_theme_palette
      session[:command_palette] = build_theme_palette
      focus.push_scope([:command_palette], origin: :command_palette)
      render_default_action
    end

    # Responds with a navigation redirect to the given URL path.
    # Used for route transitions triggered from controllers (e.g., sidebar selection).
    def navigate_to(path)
      @response = Response.navigate(path)
    end

    # Exits the application — sets a quit response that terminates the event loop.
    def quit
      @response = Response.quit
    end

    # Returns the parent application's session hash for per-request state storage (e.g., form data, flags).
    def session
      application.session
    end

    # Lazily instantiates a model class and caches it in the session under `:models`.
    # Subsequent calls with the same name return the cached instance. Used like: model(:user, UserModel)
    def model(name, model_class, **attributes)
      session[:models] ||= {}
      session[:models][name.to_sym] ||= model_class.new(**attributes)
    end

    # Submits an async task to the application's task executor (threaded or inline).
    # The task runs in a background thread; results arrive as TaskEvents in `dispatch_task`.
    def run_task(name, &block)
      application.task_executor.submit(name, &block)
    end

    # Opens the command palette (fuzzy search UI): registers the palette component and pushes it onto
    # the focus ring so input is captured inside it. Renders the default action afterward.
    def open_command_palette
      session[:command_palette] = build_command_palette
      focus.push_scope([:command_palette], origin: :command_palette)
      render_default_action
    end

    # Closes the command palette: removes it from the session, pops its scope from the focus ring,
    # and re-renders the default action. Pops all nested scopes until only the palette remains.
    def close_command_palette
      session.delete(:command_palette)
      pop_command_palette_scope
      render_default_action
    end

    # Returns or lazily initializes the Focus instance for this controller, which manages
    # keyboard-driven focus traversal between components (sidebar, content, etc.).
    # Defines focus ring slots from class-level declarations on first access.
    def focus
      @focus ||= Focus.for(session, self.class).tap do |f|
        f.define(self.class.focus_ring_slots) unless self.class.focus_ring_slots.empty?
      end
    end

    # Checks whether the given focus slot (e.g., :sidebar, :content) is currently focused.
    def focused?(slot)
      focus.focused?(slot)
    end

    # Returns whether the command palette is active in the current session.
    def command_palette_open?
      session.key?(:command_palette)
    end

    # Returns the current command palette component (fuzzy search UI) from session, if open.
    def command_palette
      session[:command_palette]
    end

    # Shifts focus to the sidebar: moves the focus ring cursor or sets `session[:focus]` to :sidebar,
    # highlights the current route index, and re-renders. Sidebar selection uses j/k keys.
    def focus_sidebar
      if focus_ring_slot?(:sidebar)
        focus.focus(:sidebar)
      else
        session[:focus] = :sidebar
      end
      session[:sidebar_index] ||= current_route_index
      render_default_action
    end

    # Shifts focus back to the main content area: moves the focus ring cursor or sets `session[:focus]` to :content,
    # and re-renders. Used by Escape key from sidebar and other navigation transitions.
    def focus_content
      if focus_ring_slot?(:content)
        focus.focus(:content)
      else
        session[:focus] = :content
      end
      render_default_action
    end

    # Returns whether the sidebar currently has focus (from focus ring or session state).
    def sidebar_focused?
      return focused?(:sidebar) if focus_ring_slot?(:sidebar)

      session[:focus] == :sidebar
    end

    # Returns whether the main content area currently has focus (from focus ring or session state).
    def content_focused?
      return focused?(:content) if focus_ring_slot?(:content)

      session[:focus] == :content
    end

    # Returns the currently highlighted sidebar item index, falling back to the current route's position
    # when no explicit sidebar selection has been made yet.
    def sidebar_index
      session[:sidebar_index] || current_route_index
    end

    private

    # Finds the position of this controller among all registered routes (for sidebar highlighting).
    # Returns 0 if no matching route is found.
    def current_route_index
      application.routes.all.index { |route| route.controller_class == self.class && route.action == :show } || 0
    end

    # Checks whether the given slot is registered as a focus ring slot for this controller.
    def focus_ring_slot?(slot)
      self.class.focus_ring_slots.include?(slot)
    end

    attr_reader :response

    # Renders `body` as a string: calls `#render` if body responds to it (component), otherwise `#to_s`.
    def render_body(body)
      body.respond_to?(:render) ? body.render.to_s : body.to_s
    end

    # Wraps `body` rendering in this controller's layout class (if one is defined).
    # If no layout is set, returns body as-is. Provides content, screen, and controller to the layout for composition.
    def render_with_layout(body)
      rendered = render_body(body)
      layout_class = self.class.layout
      return rendered unless layout_class

      render_body(layout_class.new(**layout_assigns(body, rendered)))
    end

    # Provides view assigns for layout rendering: merges body-specific assigns with standard `content`, `screen`, and `controller`.
    def layout_assigns(body, rendered)
      view_assigns(body).merge(content: rendered, screen: screen, controller: self, theme: theme)
    end

    # Extracts layout assigns from the body if it responds to `#layout_assigns` (e.g., a component),
    # otherwise returns an empty hash. Used by layout rendering for composition.
    def view_assigns(body)
      body.respond_to?(:layout_assigns) ? body.layout_assigns : {}
    end

    # Extracts the key name from the current event, handling both KeyEvent objects and raw key strings.
    # Delegates to `Charming.key_of(event)` for event-to-key resolution.
    def key_name
      Charming.key_of(event).to_s
    end

    # Dispatches a key event to the currently focused component (e.g., text input, list) by calling `#handle_key` on it.
    # Returns nil if no focused component or no handler consumed the key, otherwise :handled.
    def dispatch_to_focused_component
      slot = focus.current
      return nil unless slot && respond_to?(slot, true)

      component = send(slot)
      return nil unless component.respond_to?(:handle_key)

      result = component.handle_key(event)
      return nil if result.nil?

      render_default_action
      :handled
    end

    # Handles Tab/Shift-Tab traversal: moves focus forward or backward through the focus ring.
    # Only processes events that are actually Tab keypresses on an empty focus ring. Returns :handled when consumed.
    def dispatch_tab_traversal
      return nil unless event.is_a?(KeyEvent) && event.key == :tab
      return nil if focus.ring.empty?

      focus.cycle(event.shift ? -1 : +1)
      render_default_action
      :handled
    end

    # Dispatches key events to an open command palette (fuzzy search). Handles cancellation (Escape),
    # command execution when a selection is made, and renders the default action if no response was produced.
    def dispatch_command_palette_key
      result = command_palette.handle_key(event)
      close_command_palette if result == :cancelled
      perform_command(result.last) if selected_command?(result)
      render_default_action unless response
      response
    end

    # Mouse event handler for an open command palette. No-op — the command palette handles mouse internally.
    def dispatch_command_palette_mouse
      nil
    end

    # Dispatches keys within sidebar navigation: j/k or down/up move selection, Enter selects and navigates,
    # Escape/Tab shifts focus to content. Binds other keys to controller-specific key bindings when defined.
    def dispatch_sidebar_key
      case key_name
      when "j", "down" then sidebar_move(+1)
      when "k", "up" then sidebar_move(-1)
      when "enter" then sidebar_select
      when "escape", "tab" then focus_content
      else dispatch_sidebar_bound_key
      end
      response
    end

    # Dispatches a sidebar key to a registered controller key binding (e.g., custom hotkeys in sidebar mode).
    # Falls back to default action render if no binding exists for the key.
    def dispatch_sidebar_bound_key
      action = self.class.key_bindings[key_name]
      action ? dispatch(action) : render_default_action
    end

    # Mouse event handler for the base controller. No-op — mouse events bubble through to focused components instead.
    def dispatch_component_mouse
      nil
    end

    # Moves sidebar selection up or down by `delta`. Does nothing if there are no routes.
    def sidebar_move(delta)
      count = application.routes.all.length
      return render_default_action if count.zero?

      session[:sidebar_index] = (sidebar_index + delta).clamp(0, count - 1)
      render_default_action
    end

    # Selects the currently highlighted sidebar route and navigates to it — shifting focus to content area.
    # If no route is found at the current index, falls back to default action.
    def sidebar_select
      route = application.routes.all[sidebar_index]
      session[:focus] = :content
      route ? navigate_to(route.path) : render_default_action
    end

    # Builds a new command palette component (fuzzy search UI) from the controller's registered commands.
    # Used when opening the command palette from anywhere in the app.
    def build_command_palette
      Components::CommandPalette.new(commands: self.class.command_bindings, height: 6)
    end

    # Checks if a command palette result indicates a selected command (as opposed to cancel or no-op).
    def selected_command?(result)
      result.is_a?(Array) && result.first == :selected
    end

    # Executes a command value — either a callable block (inline command) or a method name (bound action).
    # Pops the command palette scope and re-renders unless the result is navigation or quit.
    def perform_command(command)
      current_palette = command_palette
      pop_command_palette_scope
      perform_command_value(command.value)
      session.delete(:command_palette) if command.value != :quit && command_palette.equal?(current_palette)
      render_default_action unless response&.navigate? || response&.quit?
    end

    def build_theme_palette
      Components::CommandPalette.new(commands: theme_commands, placeholder: "Search themes", height: 10)
    end

    def theme_commands
      application.class.themes.keys.map do |name|
        Components::CommandPalette::Command.new(label: theme_label(name), value: -> { use_theme(name) })
      end
    end

    def theme_label(name)
      name.to_s.tr("_", "-").split("-").map(&:capitalize).join(" ")
    end

    # Pops the command palette scope from the focus ring until it is no longer the topmost scope.
    # Called when a command executes or is cancelled.
    def pop_command_palette_scope
      focus.pop_scope while focus.ring == [:command_palette]
    end

    # Executes a command value — either calling a callable (inline block) or sending a method name to self.
    # Used for both inline commands and bound action methods from the palette.
    def perform_command_value(value)
      value.respond_to?(:call) ? instance_exec(&value) : send(value)
    end

    # Renders the default `:show` action if this controller defines it. Called after navigation, command execution,
    # or key handling when no explicit response was produced — ensures the view stays rendered.
    def render_default_action
      show if respond_to?(:show)
    end
  end
end
