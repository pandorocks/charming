# frozen_string_literal: true

require_relative "internal/renderer/differential"
require_relative "internal/terminal/memory_backend"
require_relative "internal/terminal/tty_backend"

module Charming
  class Runtime
    DEFAULT_READ_TIMEOUT = 0.05

    def initialize(application, backend: nil, renderer: nil, clock: nil)
      @application = application
      @backend = backend || Internal::Terminal::TTYBackend.new
      @renderer = renderer || Internal::Renderer::Differential.new(@backend)
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @route = @application.routes.resolve("/")
      @screen = backend_screen
      @timers = build_timers
    end

    def run
      setup_terminal
      render(resolve_response(dispatch(@route.action)))
      loop do
        event = next_timer_event || @backend.read_event(timeout: read_timeout)
        next unless event

        response = dispatch_event(event)
        next unless response
        break if response.quit?

        response = resolve_response(response)
        break if response.quit?

        render(response)
      end
    ensure
      restore_terminal
    end

    private

    attr_reader :screen

    def dispatch(action, event: nil)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch(action)
    end

    def dispatch_key(event)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch_key
    end

    def dispatch_timer(event)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch_timer
    end

    def dispatch_mouse(event)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch_mouse
    end

    def dispatch_event(event)
      return dispatch_resize(event) if event.is_a?(ResizeEvent)
      return dispatch_timer(event) if event.is_a?(TimerEvent)
      return dispatch_mouse(event) if event.is_a?(MouseEvent)

      dispatch_key(event)
    end

    def dispatch_resize(event)
      @screen = Screen.new(width: event.width, height: event.height)
      dispatch(@route.action, event: event)
    end

    def resolve_response(response)
      return response unless response.navigate?

      @route = @application.routes.resolve(response.path)
      @timers = build_timers
      dispatch(@route.action)
    end

    def backend_screen
      width, height = @backend.size
      Screen.new(width: width, height: height)
    end

    def render(response)
      @renderer.render(response.body)
    end

    def build_timers
      now = clock_now
      @route.controller_class.timer_bindings.values.map do |binding|
        { binding: binding, next_at: now + binding.interval }
      end
    end

    def next_timer_event
      timer = due_timer
      return unless timer

      now = clock_now
      timer[:next_at] = now + timer.fetch(:binding).interval
      TimerEvent.new(name: timer.fetch(:binding).name, now: now)
    end

    def due_timer
      now = clock_now
      @timers.select { |timer| timer.fetch(:next_at) <= now }.min_by { |timer| timer.fetch(:next_at) }
    end

    def read_timeout
      next_at = @timers.map { |timer| timer.fetch(:next_at) }.min
      return DEFAULT_READ_TIMEOUT unless next_at

      [next_at - clock_now, 0].max
    end

    def clock_now
      @clock.call
    end

    def setup_terminal
      @backend.enter_alt_screen
      @backend.hide_cursor
      @backend.install_resize_handler if @backend.respond_to?(:install_resize_handler)
    end

    def restore_terminal
      @backend.restore_resize_handler if @backend.respond_to?(:restore_resize_handler)
      @backend.show_cursor
      @backend.leave_alt_screen
    end
  end
end
