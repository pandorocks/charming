# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
      module ControllerTemplate
        def controller
          %(# frozen_string_literal: true

module #{name.class_name}
  class HomeController < Charming::Controller
#{controller_key_bindings}
#{controller_actions}
#{controller_helpers}
  end
end
)
        end

        def controller_key_bindings
          %(    ("a".."z").each { |letter| key letter, :handle_key }
    ("0".."9").each { |number| key number, :handle_key }
    %w[space backspace delete up down home end enter escape].each do |name|
      key name, :handle_key
    end)
        end

        def controller_actions
          %(
    def show
      render_home
    end

    def handle_key
      if palette_open?
        handle_palette_key
      else
        handle_app_key
      end

      render_home unless response
    end)
        end

        def controller_helpers
          %(

    private
#{event_helpers}
#{palette_helpers}
#{command_helpers}
#{render_helpers})
        end

        def event_helpers
          %(
    def handle_app_key
      case event.key.to_sym
      when :p then open_palette
      when :q then quit
      end
    end

    def handle_palette_key
      result = palette.handle_key(event)
      close_palette if result == :cancelled
      apply_command(result.last) if selected?(result)
    end)
        end

        def palette_helpers
          %(

    def open_palette
      session[:palette] = build_palette
    end

    def close_palette
      session.delete(:palette)
    end

    def palette_open?
      session.key?(:palette)
    end

    def palette
      session[:palette]
    end)
        end

        def command_helpers
          %(

    def build_palette
      Charming::Components::CommandPalette.new(commands: commands, height: 6)
    end

    def commands
      [
        command("Close palette", :close_palette),
        command("Quit app", :quit)
      ]
    end

    def command(label, value)
      Charming::Components::CommandPalette::Command.new(label: label, value: value)
    end)
        end

        def render_helpers
          %(

    def selected?(result)
      result.is_a?(Array) && result.first == :selected
    end

    def apply_command(command)
      send(command.value)
      close_palette unless command.value == :quit
    end

    def render_home
      render HomeView.new(palette: palette)
    end)
        end
      end
    end
  end
end
