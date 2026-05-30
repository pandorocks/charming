# frozen_string_literal: true

module Charming
  module Components
    class CommandPalette < Component
      Command = Data.define(:label, :value)

      attr_reader :commands, :input

      def initialize(commands:, placeholder: "Search commands", height: nil, value: "", cursor: nil, selected_index: 0)
        super()
        @commands = commands
        @height = height
        @input = TextInput.new(value: value, placeholder: placeholder, cursor: cursor)
        @list = build_list(selected_index: selected_index)
      end

      def selected_command
        list.selected_item
      end

      def state
        {
          value: input.value,
          cursor: input.cursor,
          selected_index: list.selected_index
        }
      end

      def handle_key(event)
        key = Charming.key_of(event)
        return :cancelled if key.to_sym == :escape

        return handle_list_key(event) if list_key?(key)

        handle_input_key(event)
      end

      def render
        [input.render, render_results].join("\n")
      end

      private

      attr_reader :height, :list

      def handle_list_key(event)
        list.handle_key(event)
      end

      def handle_input_key(event)
        result = input.handle_key(event)
        @list = build_list if result == :handled
        result
      end

      def list_key?(key)
        %i[up down home end enter].include?(key.to_sym)
      end

      def render_results
        return "No commands found" if filtered_commands.empty?

        list.render
      end

      def build_list(selected_index: list&.selected_index || 0)
        List.new(items: filtered_commands, selected_index: selected_index, height: height, label: :label.to_proc)
      end

      def filtered_commands
        return commands if input.value.empty?

        commands.select do |command|
          command.label.downcase.include?(input.value.downcase)
        end
      end
    end
  end
end
