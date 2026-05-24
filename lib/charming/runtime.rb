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
    end

    def run
      setup_terminal
      render(dispatch(@route.action))
      loop do
        event = @backend.read_event(timeout: 0.05)
        next unless event

        response = dispatch_key(event)
        next unless response
        break if response.quit?

        render(response)
      end
    ensure
      restore_terminal
    end

    private

    def dispatch(action, event: nil)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch(action)
    end

    def dispatch_key(event)
      @route.controller_class.new(application: @application, event: event, screen: screen).dispatch_key
    end

    def screen
      width, height = @backend.size
      Screen.new(width: width, height: height)
    end

    def render(response)
      @renderer.render(response.body)
    end

    def setup_terminal
      @backend.enter_alt_screen
      @backend.hide_cursor
    end

    def restore_terminal
      @backend.show_cursor
      @backend.leave_alt_screen
    end
  end
end
