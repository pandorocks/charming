# frozen_string_literal: true

module Charming
  class Controller
    module CommandPalette
      def open_command_palette
        session[:command_palette] = command_palette_state(:commands)
        focus.push_scope([:command_palette], origin: :command_palette)
        render_default_action
      end

      def close_command_palette
        session.delete(:command_palette)
        pop_command_palette_scope
        render_default_action
      end

      def command_palette_open?
        session.key?(:command_palette)
      end

      def command_palette
        build_command_palette_from_state(session[:command_palette]) if command_palette_open?
      end

      private

      def dispatch_command_palette_key
        palette = command_palette
        result = palette.handle_key(event)

        if result == :cancelled
          close_command_palette
        elsif selected_command?(result)
          perform_command(result.last)
        else
          save_command_palette_state(palette)
          render_default_action unless response
        end

        response
      end

      def dispatch_command_palette_mouse
        nil
      end

      def build_command_palette_from_state(state)
        case state.fetch(:type)
        when :commands
          build_command_palette_with_state(self.class.command_bindings, state, height: 6)
        when :themes
          build_command_palette_with_state(theme_commands, state, placeholder: "Search themes", height: 10)
        end
      end

      def build_command_palette_with_state(commands, state, placeholder: "Search commands", height: nil)
        Presentation::Components::CommandPalette.new(
          commands: commands,
          placeholder: placeholder,
          height: height,
          value: state.fetch(:value),
          cursor: state.fetch(:cursor),
          selected_index: state.fetch(:selected_index),
          theme: theme
        )
      end

      def command_palette_state(type)
        {type: type, value: "", cursor: 0, selected_index: 0}
      end

      def save_command_palette_state(palette)
        session[:command_palette] = session.fetch(:command_palette).merge(palette.state)
      end

      def selected_command?(result)
        result.is_a?(Array) && result.first == :selected
      end

      def perform_command(command)
        current_palette_state = session[:command_palette]
        pop_command_palette_scope
        perform_command_value(command.value)
        if command.value != :quit && session[:command_palette].equal?(current_palette_state)
          session.delete(:command_palette)
        end
        render_default_action unless response&.navigate? || response&.quit?
      end

      def theme_commands
        application.class.themes.keys.map do |name|
          Presentation::Components::CommandPalette::Command.new(label: theme_label(name), value: -> { use_theme(name) })
        end
      end

      def theme_label(name)
        name.to_s.tr("_", "-").split("-").map(&:capitalize).join(" ")
      end

      def pop_command_palette_scope
        focus.pop_scope while focus.ring == [:command_palette]
      end

      def perform_command_value(value)
        value.respond_to?(:call) ? instance_exec(&value) : send(value)
      end
    end
  end
end
