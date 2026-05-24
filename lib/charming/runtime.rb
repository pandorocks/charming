# frozen_string_literal: true

require_relative "internal/renderer/full_repaint"
require_relative "internal/terminal/memory_backend"
require_relative "internal/terminal/tty_backend"

module Charming
  class Runtime
    def initialize(application, backend: nil, renderer: nil)
      @application = application
      @backend = backend || Internal::Terminal::TTYBackend.new
      @renderer = renderer || Internal::Renderer::FullRepaint.new(@backend)
      @route = @application.routes.resolve("/")
      @screen = backend_screen
    end

    def run
      setup_terminal
      render(dispatch(@route.action))
      loop do
        event = @backend.read_event(timeout: 0.05)
        next unless event

        response = dispatch_event(event)
        next unless response
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

    def dispatch_event(event)
      return dispatch_resize(event) if event.is_a?(ResizeEvent)

      dispatch_key(event)
    end

    def dispatch_resize(event)
      @screen = Screen.new(width: event.width, height: event.height)
      dispatch(@route.action, event: event)
    end

    def backend_screen
      width, height = @backend.size
      Screen.new(width: width, height: height)
    end

    def render(response)
      @renderer.render(response.body)
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
