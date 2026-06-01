# frozen_string_literal: true

module Charming
  module Presentation
    module UI
      # ANSISlicer extracts a visible substring from a string that may contain ANSI
      # escape sequences, preserving the styling that is active at the start of
      # the slice and emitting a trailing reset if any styled content was copied.
      class ANSISlicer
        def self.slice(line, start_column, width)
          return "" unless width.positive?

          slice_range(line.to_s, start_column, start_column + width)
        end

        def self.slice_range(line, start_column, end_column)
          state = {column: 0, output: +"", active: [], started: false, styled: false}

          each_ansi_or_char(line) do |token, ansi|
            if ansi
              slice_ansi_token(token, state, start_column, end_column)
            else
              slice_char(token, state, start_column, end_column)
            end
          end

          terminate_slice(state)
        end

        def self.each_ansi_or_char(line)
          index = 0
          while index < line.length
            match = line.match(Width::ANSI_PATTERN, index)
            if match&.begin(0) == index
              yield match[0], true
              index = match.end(0)
            else
              yield line[index], false
              index += 1
            end
          end
        end

        def self.slice_ansi_token(token, state, start_column, end_column)
          started = state[:started]
          update_active_styles(state[:active], token)
          return unless state[:column].between?(start_column, end_column - 1)

          start_slice(state)
          if started
            state[:output] << token
            state[:styled] = !token.include?("[0m")
          end
        end

        def self.slice_char(char, state, start_column, end_column)
          char_width = Width.measure(char)
          char_start = state[:column]
          char_end = char_start + char_width
          state[:column] = char_end
          return unless char_end > start_column && char_start < end_column

          start_slice(state)
          state[:output] << char
        end

        def self.start_slice(state)
          return if state[:started]

          state[:output] << state[:active].join
          state[:styled] = true unless state[:active].empty?
          state[:started] = true
        end

        def self.terminate_slice(state)
          return state[:output] if !state[:styled] || state[:output].empty?

          "#{state[:output]}\e[0m"
        end

        def self.update_active_styles(active, token)
          if token.include?("[0m")
            active.clear
          else
            active << token
          end
        end

        private_class_method :each_ansi_or_char, :slice_ansi_token, :slice_char,
          :start_slice, :terminate_slice, :update_active_styles
      end
    end
  end
end
