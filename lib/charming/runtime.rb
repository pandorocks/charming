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
    end

    # Runs the event loop: enters alt-screen, dispatches incoming events
    # (key, mouse, timer, async task), renders controller responses, and
    # restores terminal state on exit.
    def run
      setup_terminal
      render(resolve_response(dispatch(@route.action)))
      loop do
        event = next_task_event || next_timer_event || @backend.read_event(timeout: read_timeout)
        next unless event

        response = dispatch_event(event)
        next unless response
        break if response.quit?

        response = resolve_response(response)
        break if response.quit?

        render(response)
      end
    ensure
      @task_executor&.shutdown(timeout: 0.0)
      restore_terminal
    end

    private

    attr_reader :screen

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

    # Dispatches a mouse action (click, drag, scroll) to the current route's controller.
    def dispatch_mouse(event)
      controller(event: event).dispatch_mouse
    end

    def controller(event: nil)
      @route.controller_class.new(application: @application, event: event, params: @route.params, screen: screen, route: @route)
    end

    # Type-based dispatcher: routes resize, task, timer, mouse, and key events
    # to the appropriate handler. Falls back to key dispatch for unclassified events.
    def dispatch_event(event)
      return dispatch_resize(event) if event.is_a?(Events::ResizeEvent)
      return dispatch_task(event) if event.is_a?(Events::TaskEvent)
      return dispatch_timer(event) if event.is_a?(Events::TimerEvent)
      return dispatch_mouse(event) if event.is_a?(Events::MouseEvent)

      dispatch_key(event)
    end

    # Dispatches a resize event: updates screen dimensions and re-renders the current action.
    def dispatch_resize(event)
      @screen = Screen.new(width: event.width, height: event.height)
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
      @backend.install_resize_handler if @backend.respond_to?(:install_resize_handler)
    end

    # Restores terminal state: reinstalls any previous resize handler, shows
    # the cursor, and leaves the alternative screen buffer.
    def restore_terminal
      @backend.restore_resize_handler if @backend.respond_to?(:restore_resize_handler)
      @backend.show_cursor
      @backend.leave_alt_screen
    end
  end
end
