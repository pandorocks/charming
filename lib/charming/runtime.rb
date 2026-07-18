# frozen_string_literal: true

module Charming
  # Runtime manages a terminal UI application's lifecycle: setting up an
  # alternative-screen terminal with cursor hiding, running an event loop that
  # reads keyboard, mouse, timer, and task events, dispatching them to
  # controllers, rendering responses, and tearing down cleanly on exit.
  class Runtime
    DEFAULT_READ_TIMEOUT = Internal::EventLoop::DEFAULT_READ_TIMEOUT

    def initialize(application, backend: nil, renderer: nil, clock: nil, task_executor: nil)
      @application = application
      @backend = backend || Internal::Terminal::TTYBackend.new
      @renderer = renderer || Internal::Renderer::Differential.new(@backend)
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @task_queue = Thread::Queue.new
      @task_executor = build_task_executor(task_executor)
      @application.task_executor = @task_executor
      @route = @application.routes.resolve("/")
      @screen = backend_screen
      @coalesce_input = @application.respond_to?(:coalesce_input?) && @application.coalesce_input?
      @event_loop = build_event_loop
    end

    # Runs the event loop: enters alt-screen, dispatches incoming events
    # (key, mouse, timer, async task), renders controller responses, and
    # restores terminal state on exit. Unhandled exceptions from controller
    # actions render an ErrorScreen instead of crashing the terminal.
    def run
      setup_terminal
      install_interrupt_handler
      with_raw_input do
        render(initial_response)
        @event_loop.run { |event| process(event) }
      ensure
        restore_interrupt_handler
        @task_executor&.shutdown(timeout: 2.0)
        @application.save_session if @application.respond_to?(:save_session)
        restore_terminal
      end
    end

    private

    attr_reader :screen

    # Builds the event pump, wiring in the current controller's timer bindings and
    # an interrupt check backed by the SIGINT flag set in install_interrupt_handler.
    def build_event_loop
      Internal::EventLoop.new(
        backend: @backend,
        clock: @clock,
        task_queue: @task_queue,
        timer_bindings: @route.controller_class.timer_bindings.values,
        coalesce_input: @coalesce_input,
        interrupted: -> { @interrupted }
      )
    end

    # The first frame's response — the root route's action, with errors caught. Out-of-band escape
    # sequences registered while rendering are collected and attached to the response.
    def initial_response
      response = nil
      escapes = Escape.collecting { response = resolve_response(dispatch(@route.action)) }
      attach_escapes(response, escapes)
    rescue => e
      error_response(e)
    end

    # Handles a single event. Returns :quit to stop the loop, nil otherwise.
    # While an error screen is showing, only key events are honored: q quits,
    # any other key dismisses and re-renders the current route.
    def process(event)
      return process_error_event(event) if @error
      return :quit if unbound_interrupt?(event)

      response = nil
      escapes = Escape.collecting do
        response = dispatch_event(event)
        response = resolve_response(response) if response
      end
      return unless response
      return :quit if response.quit?

      render(attach_escapes(response, escapes))
      nil
    rescue => e
      render(error_response(e))
      nil
    end

    # Error-mode event handling: q quits, any other key dismisses the error
    # and re-dispatches the current route's action. Timer/task events are ignored.
    def process_error_event(event)
      return unless event.is_a?(Events::KeyEvent)
      return :quit if Charming.key_of(event) == :q

      @error = nil
      render(initial_response)
      nil
    end

    # True for a Ctrl+C key press that the current controller has no binding for —
    # the runtime treats it as quit so apps always have an escape hatch. Controllers
    # can take over by binding "ctrl+c" themselves.
    def unbound_interrupt?(event)
      return false unless event.is_a?(Events::KeyEvent)
      return false unless event.ctrl && event.key == :c

      @route.controller_class.key_bindings[:"ctrl+c"].nil?
    end

    # Traps SIGINT so Ctrl+C (when delivered as a signal rather than a key) exits the
    # loop cleanly through the ensure block instead of crashing mid-frame.
    def install_interrupt_handler
      @interrupted = false
      @previous_int_handler = Signal.trap("INT") { @interrupted = true }
    rescue ArgumentError
      @previous_int_handler = nil
    end

    # Restores the previous SIGINT handler installed before the runtime started.
    def restore_interrupt_handler
      Signal.trap("INT", @previous_int_handler || "DEFAULT")
    rescue ArgumentError
      nil
    end

    # Records *error*, logs its backtrace, and builds a centered ErrorScreen response.
    def error_response(error)
      @error = error
      @application.logger.error("#{error.class}: #{error.message}\n#{Array(error.backtrace).join("\n")}")
      panel = Components::ErrorScreen.new(error: error, theme: @application.theme).render
      Response.render(UI.center(panel, width: screen.width, height: screen.height))
    end

    # Dispatches an action on the current route's controller with an optional event.
    # Entry point from the event loop into controllers.
    def dispatch(action, event: nil)
      controller(event: event).dispatch(action)
    end

    # Dispatches a key press to the current route's controller.
    def dispatch_key(event)
      controller(event: event).dispatch_key
    end

    # Dispatches a timer tick to the current route's controller.
    def dispatch_timer(event)
      controller(event: event).dispatch_timer
    end

    # Dispatches an async task result to the current route's controller.
    def dispatch_task(event)
      controller(event: event).dispatch_task
    end

    # Dispatches a task progress report to the current route's controller.
    def dispatch_task_progress(event)
      controller(event: event).dispatch_task_progress
    end

    # Dispatches a mouse action (click, drag, scroll) to the current route's controller.
    def dispatch_mouse(event)
      controller(event: event).dispatch_mouse
    end

    # Instantiates a fresh controller for the active route, passing the application, current *event*,
    # route params, screen dimensions, and route object. Called by every dispatch path.
    def controller(event: nil)
      @route.controller_class.new(application: @application, event: event, params: @route.params, screen: screen, route: @route)
    end

    # Type-based dispatcher: routes resize, task, progress, timer, mouse, paste, and key
    # events to the appropriate handler. Falls back to key dispatch for unclassified events.
    def dispatch_event(event)
      return dispatch_resize(event) if event.is_a?(Events::ResizeEvent)
      return dispatch_task(event) if event.is_a?(Events::TaskEvent)
      return dispatch_task_progress(event) if event.is_a?(Events::TaskProgressEvent)
      return dispatch_timer(event) if event.is_a?(Events::TimerEvent)
      return dispatch_mouse(event) if event.is_a?(Events::MouseEvent)
      return dispatch_paste(event) if event.is_a?(Events::PasteEvent)
      return dispatch_focus_change(event) if event.is_a?(Events::FocusEvent)

      dispatch_key(event)
    end

    # Dispatches a terminal focus change to the controller's optional `focus_changed`
    # action. Ignored when the controller doesn't define one.
    def dispatch_focus_change(event)
      ctrl = controller(event: event)
      return nil unless ctrl.respond_to?(:focus_changed)

      ctrl.dispatch(:focus_changed)
    end

    # Dispatches pasted text to the current route's controller.
    def dispatch_paste(event)
      controller(event: event).dispatch_paste
    end

    # Dispatches a resize event: updates screen dimensions and re-renders the current action.
    # The renderer's cached previous frame is invalidated and the backend is cleared so the
    # new-dimension frame paints onto a clean alt-screen instead of overlaying stale rows.
    def dispatch_resize(event)
      @screen = Screen.new(width: event.width, height: event.height)
      @renderer.invalidate if @renderer.respond_to?(:invalidate)
      @backend.clear if @backend.respond_to?(:clear)
      dispatch(@route.action, event: event)
    end

    # Follows navigation responses: resolves the new route from the router,
    # reschedules the event loop's timers for the new controller, and
    # dispatches that route's action.
    def resolve_response(response)
      return response unless response.navigate?

      @route = @application.routes.resolve(response.path)
      @event_loop.reset_timers(@route.controller_class.timer_bindings.values)
      dispatch(@route.action)
    end

    # Derives Screen dimensions (width, height) from the terminal backend.
    def backend_screen
      width, height = @backend.size
      Screen.new(width: width, height: height)
    end

    # Renders a response: first flushes any out-of-band escape sequences (image transmissions,
    # clipboard writes, notifications, title changes) straight to the backend — ahead of the frame so
    # image data is registered before its placeholder cells reference it — then renders the body.
    def render(response)
      flush_escapes(response)
      @renderer.render(response.body)
    end

    # Writes a response's out-of-band escape sequences to the backend, ahead of the frame. No-op for
    # backends that don't support them or responses that carry none.
    def flush_escapes(response)
      return unless @backend.respond_to?(:write_escape)

      response.escapes&.each { |sequence| @backend.write_escape(sequence) }
    end

    # Returns *response* with *escapes* appended, or unchanged when none were collected.
    def attach_escapes(response, escapes)
      return response if escapes.nil? || escapes.empty?

      response.with(escapes: response.escapes + escapes)
    end

    # Constructs a task executor: supports explicit instances, callable factories, or the default Threaded executor.
    def build_task_executor(task_executor)
      return Tasks::ThreadedExecutor.new(@task_queue) unless task_executor
      return task_executor if task_executor.respond_to?(:submit)
      return task_executor.call(@task_queue) if task_executor.respond_to?(:call) && !task_executor.respond_to?(:new)

      task_executor.new(@task_queue)
    end

    # Returns the clock proc, providing a single point of access for time in the event loop.
    def clock_now
      @clock.call
    end

    # Enters an alternative screen buffer, hides the cursor, and installs
    # a terminal resize signal handler if supported by the backend. Also asks
    # the terminal for its background color so adaptive colors resolve correctly.
    def setup_terminal
      detect_background
      @backend.enter_alt_screen
      @backend.hide_cursor
      @backend.enable_mouse_tracking if @backend.respond_to?(:enable_mouse_tracking)
      @backend.enable_bracketed_paste if @backend.respond_to?(:enable_bracketed_paste)
      @backend.enable_focus_reporting if @backend.respond_to?(:enable_focus_reporting)
      @backend.install_resize_handler if @backend.respond_to?(:install_resize_handler)
    end

    # Feeds the terminal's OSC 11 background reply (when the backend can obtain
    # one) into UI::Background so adaptive colors resolve against reality rather
    # than the dark-background default.
    def detect_background
      return unless @backend.respond_to?(:query_background_color)

      background = @backend.query_background_color
      UI::Background.assume = background if background
    end

    # Keeps input raw/no-echo across rendering and dispatch, not just during reads.
    def with_raw_input(&block)
      return yield unless @backend.respond_to?(:with_raw_input)

      @backend.with_raw_input(&block)
    end

    # Restores terminal state: reinstalls any previous resize handler, shows
    # the cursor, and leaves the alternative screen buffer.
    def restore_terminal
      @backend.restore_resize_handler if @backend.respond_to?(:restore_resize_handler)
      @backend.disable_focus_reporting if @backend.respond_to?(:disable_focus_reporting)
      @backend.disable_bracketed_paste if @backend.respond_to?(:disable_bracketed_paste)
      @backend.disable_mouse_tracking if @backend.respond_to?(:disable_mouse_tracking)
      @backend.show_cursor
      @backend.leave_alt_screen
    end
  end
end
