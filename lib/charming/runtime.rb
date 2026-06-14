# frozen_string_literal: true

module Charming
  # Runtime manages a terminal UI application's lifecycle: setting up an
  # alternative-screen terminal with cursor hiding, running an event loop that
  # reads keyboard, mouse, timer, and task events, dispatching them to
  # controllers, rendering responses, and tearing down cleanly on exit.
  class Runtime
    DEFAULT_READ_TIMEOUT = 0.05

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
      @timers = build_timers
      @pending_event = nil
      @coalesce_input = @application.respond_to?(:coalesce_input?) && @application.coalesce_input?
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
        loop do
          break if @interrupted

          event = next_task_event || next_timer_event || next_input_event
          unless event
            break if backend_exhausted?
            next
          end
          break if process(event) == :quit
        end
      end
    ensure
      restore_interrupt_handler
      @task_executor&.shutdown(timeout: 2.0)
      @application.save_session if @application.respond_to?(:save_session)
      restore_terminal
    end

    private

    attr_reader :screen

    # The first frame's response — the root route's action, with errors caught.
    def initial_response
      resolve_response(dispatch(@route.action))
    rescue => e
      error_response(e)
    end

    # Handles a single event. Returns :quit to stop the loop, nil otherwise.
    # While an error screen is showing, only key events are honored: q quits,
    # any other key dismisses and re-renders the current route.
    def process(event)
      return process_error_event(event) if @error
      return :quit if unbound_interrupt?(event)

      response = dispatch_event(event)
      return unless response
      return :quit if response.quit?

      response = resolve_response(response)
      return :quit if response.quit?

      render(response)
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

    # True when the backend reports it has no more events to deliver (test backends
    # only — the TTY backend never exhausts). Prevents the loop from spinning forever
    # in tests that forget a trailing quit event.
    def backend_exhausted?
      @backend.respond_to?(:exhausted?) && @backend.exhausted?
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
    # resets timers for the new route, and dispatches that route's action.
    def resolve_response(response)
      return response unless response.navigate?

      @route = @application.routes.resolve(response.path)
      @timers = build_timers
      dispatch(@route.action)
    end

    # Derives Screen dimensions (width, height) from the terminal backend.
    def backend_screen
      width, height = @backend.size
      Screen.new(width: width, height: height)
    end

    # Renders the body portion of a response through the renderer.
    def render(response)
      @renderer.render(response.body)
    end

    # Builds the initial set of timer states from controller bindings and the current clock time.
    def build_timers
      now = clock_now
      @route.controller_class.timer_bindings.values.map do |binding|
        {binding: binding, next_at: now + binding.interval}
      end
    end

    # Returns a TimerEvent for the first due timer and advances its next fire time.
    # Returns nil if no timers are ready or registered.
    def next_timer_event
      timer = due_timer
      return unless timer

      now = clock_now
      timer[:next_at] = now + timer.fetch(:binding).interval
      Events::TimerEvent.new(name: timer.fetch(:binding).name, now: now)
    end

    # Pops a task event from the thread-safe queue if one is available.
    # Non-blocking — returns nil immediately when the queue is empty.
    def next_task_event
      @task_queue.pop(true)
    rescue ThreadError
      nil
    end

    # Reads the next input event, consuming a stashed event first, then collapsing any
    # auto-repeat burst behind it.
    def next_input_event
      event = @pending_event
      @pending_event = nil
      event ||= @backend.read_event(timeout: read_timeout)
      return event unless event && @coalesce_input

      coalesce(event)
    end

    # Collapses a run of identical key events — the flood the terminal emits while a key is
    # held down — into a single dispatched event, so holding a key can't queue a backlog that
    # keeps acting after release. The first non-matching event encountered is stashed for the
    # next loop iteration, so distinct keys and non-key events (resize/paste/mouse) are never
    # lost. Only KeyEvents are coalesced; everything else passes straight through.
    def coalesce(event)
      return event unless event.is_a?(Events::KeyEvent)

      # Only read while input is *immediately* available, so the drain never blocks on an
      # empty buffer (read_event itself can wait up to ~0.1s; input_pending? is a true 0s check).
      while @backend.input_pending?
        nxt = @backend.read_event(timeout: 0)
        break unless nxt
        next if nxt == event # identical auto-repeat — discard the older one, keep draining

        @pending_event = nxt
        break
      end
      event
    end

    # Returns timer values due at or before `now`, sorted by next fire time.
    def due_timer
      now = clock_now
      @timers.select { |timer| timer.fetch(:next_at) <= now }.min_by { |timer| timer.fetch(:next_at) }
    end

    # Computes how long to block waiting for input based on when the next timer is due,
    # clamped between 0 and DEFAULT_READ_TIMEOUT (0.05s). Returns DEFAULT when no timers exist.
    def read_timeout
      next_at = @timers.map { |timer| timer.fetch(:next_at) }.min
      return DEFAULT_READ_TIMEOUT unless next_at

      (next_at - clock_now).clamp(0, DEFAULT_READ_TIMEOUT)
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
    # a terminal resize signal handler if supported by the backend.
    def setup_terminal
      @backend.enter_alt_screen
      @backend.hide_cursor
      @backend.enable_mouse_tracking if @backend.respond_to?(:enable_mouse_tracking)
      @backend.enable_bracketed_paste if @backend.respond_to?(:enable_bracketed_paste)
      @backend.enable_focus_reporting if @backend.respond_to?(:enable_focus_reporting)
      @backend.install_resize_handler if @backend.respond_to?(:install_resize_handler)
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
