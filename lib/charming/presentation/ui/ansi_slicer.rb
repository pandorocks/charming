# frozen_string_literal: true

module Charming
  module UI
    # ANSISlicer extracts a visible substring from a string that may contain ANSI
    # escape sequences, preserving the styling that is active at the start of
    # the slice and emitting a trailing reset if any styled content was copied.
    class ANSISlicer
      # One ANSI escape sequence or one grapheme cluster (`\X`). The ANSI branch
      # comes first so a valid escape is consumed whole rather than as graphemes.
      TOKEN_PATTERN = /#{Width::ANSI_PATTERN}|\X/

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
        # Iterate one ANSI escape or one *grapheme cluster* (`\X`) at a time. A
        # single emoji may be several codepoints (ZWJ sequences, skin-tone and
        # variation selectors, e.g. "🧙‍♂️"); treating it as one unit keeps its full
        # display width together so a slice never splits it mid-glyph.
        line.scan(TOKEN_PATTERN) do |token|
          yield token, token.start_with?("\e")
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

        visible = [char_end, end_column].min - [char_start, start_column].max
        return unless visible.positive?

        start_slice(state)
        # A multi-column glyph cut by a slice boundary cannot be partially drawn,
        # so render the in-range columns as spaces (standard terminal behavior).
        # This keeps the slice exactly *width* columns wide regardless of where
        # the boundaries fall relative to wide glyphs.
        fits = char_start >= start_column && char_end <= end_column
        state[:output] << (fits ? char : " " * visible)
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
          active << token unless active.include?(token)
        end
      end

      private_class_method :each_ansi_or_char, :slice_ansi_token, :slice_char,
        :start_slice, :terminate_slice, :update_active_styles
    end
  end
end
