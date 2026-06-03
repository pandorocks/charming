# frozen_string_literal: true

require "unicode/display_width"

module Charming
  module Components
    # Viewport is a scrollable region over multi-line content. Supports keyboard scrolling
    # (up/down/left/right, page up/down, home/end) and mouse interactions (scroll wheel and
    # click-to-position). Lines are clipped with ANSI awareness via `UI::ANSISlicer` so styled
    # text is preserved across horizontal scrolls. When `wrap:` is true, long lines are wrapped
    # to the configured *width* before scrolling.
    class Viewport < Component
      include KeyboardHandler

      # Matches an ANSI SGR escape sequence (e.g., "\e[31m" for red foreground).
      ANSI_PATTERN = /\e\[[0-9;]*m/

      # Maps scroll keys to the instance methods that perform them via KeyboardHandler.
      KEY_ACTIONS = {
        up: :scroll_up,
        down: :scroll_down,
        page_up: :page_up,
        page_down: :page_down,
        home: :scroll_home,
        end: :scroll_end,
        left: :scroll_left,
        right: :scroll_right
      }.freeze

      # The current top-visible row and left-visible column, respectively.
      attr_reader :offset, :column

      # *content* may be a string, an array of lines, or any object responding to `render`.
      # *width* and *height* constrain the visible window; *offset* is the top-visible row
      # and *column* is the left-visible column. *wrap* enables soft-wrapping of long lines.
      def initialize(content:, width: nil, height: nil, offset: 0, column: 0, wrap: false, keymap: :vim)
        super()
        @content = content
        @width = width
        @height = height
        @offset = offset
        @column = column
        @wrap = wrap
        @keymap = keymap
        clamp_position
      end

      # Renders the visible window of content as a multi-line string.
      def render
        visible_lines.map { |line| render_line(line) }.join("\n")
      end

      # Handles mouse events: scroll wheel adjusts the row offset, click moves the top
      # visible row to the clicked position. Returns :handled on success.
      def handle_mouse(event)
        return nil unless height

        if event.scroll?
          scroll_delta = (event.button_name == :scroll_up) ? -1 : 1
          @offset += scroll_delta
          clamp_position
          return :handled
        end

        return nil unless event.click?

        clicked_row = event.y
        return nil if clicked_row < offset || clicked_row >= offset + viewport_height

        @offset = clicked_row
        clamp_position
        :handled
      end

      private

      attr_reader :content, :width, :height

      # Scrolls the viewport up by one row.
      def scroll_up
        @offset -= 1
        clamp_position
      end

      # Scrolls the viewport down by one row.
      def scroll_down
        @offset += 1
        clamp_position
      end

      # Scrolls up by one viewport page.
      def page_up
        @offset -= page_size
        clamp_position
      end

      # Scrolls down by one viewport page.
      def page_down
        @offset += page_size
        clamp_position
      end

      # Scrolls to the top-left of the content.
      def scroll_home
        @offset = 0
        @column = 0
      end

      # Scrolls to the bottom-right of the content.
      def scroll_end
        @offset = max_offset
        @column = max_column
      end

      # Scrolls one column left.
      def scroll_left
        @column -= 1
        clamp_position
      end

      # Scrolls one column right.
      def scroll_right
        @column += 1
        clamp_position
      end

      # Clamps both the row offset and the column to their valid ranges.
      def clamp_position
        @offset = offset.clamp(0, max_offset)
        @column = column.clamp(0, max_column)
      end

      # Returns the slice of content lines visible in the current viewport, padded to *height*.
      def visible_lines
        lines = content_lines.slice(offset, viewport_height) || []
        return lines unless height

        lines + Array.new([height - lines.length, 0].max, "")
      end

      # Renders a single line according to the configured width and wrap mode: clips to the
      # visible column window when not wrapping, otherwise wraps the line to the width.
      def render_line(line)
        return line unless width
        return pad_line(line, width) if wrap?

        pad_line(clip_line(line), width)
      end

      # Clips *line* to the visible column window while preserving active ANSI styling.
      def clip_line(line)
        clipped = clip_tokens(line.to_s)
        needs_reset?(clipped) ? "#{clipped}\e[0m" : clipped
      end

      # Walks *line* token-by-token, copying ANSI escapes through and emitting only the
      # characters that fall inside the visible column window.
      def clip_tokens(line)
        state = {cursor: 0, output: +""}
        line.scan(/#{ANSI_PATTERN}|./mo) do |token|
          ansi?(token) ? append_ansi(state, token) : append_character(state, token)
        end
        state.fetch(:output)
      end

      # Appends an ANSI escape token to the output buffer unchanged.
      def append_ansi(state, token)
        state.fetch(:output) << token
      end

      # Appends a single character token to the output buffer when it falls inside the
      # visible column window, advancing the visual cursor.
      def append_character(state, char)
        char_width = Unicode::DisplayWidth.of(char)
        cursor = state.fetch(:cursor)
        state.fetch(:output) << char if visible?(cursor, char_width)
        state[:cursor] = cursor + char_width
      end

      # True when the character at *cursor* (with the given display *char_width*) is within
      # the visible column window.
      def visible?(cursor, char_width)
        cursor >= column && cursor + char_width <= column + width
      end

      # True when *value* contains ANSI codes but does not end with a reset — needed because
      # the clip may truncate styling in the middle of a styled run.
      def needs_reset?(value)
        value.match?(ANSI_PATTERN) && !value.end_with?("\e[0m")
      end

      # Pads *line* to *target_width* with trailing spaces, leaving the line itself unchanged.
      def pad_line(line, target_width)
        line + (" " * [target_width - UI::Width.measure(line), 0].max)
      end

      # Returns the content lines, wrapped to *width* when wrap is enabled.
      def content_lines
        return wrapped_content_lines if wrap?

        rendered_content.lines(chomp: true)
      end

      # Wraps the content to *width* via UI::visible_slice, returning an array of wrapped lines.
      def wrapped_content_lines
        rendered_content.lines(chomp: true).flat_map { |line| wrap_line(line) }
      end

      # Wraps a single *line* into chunks of *width* display columns.
      def wrap_line(line)
        line_width = UI::Width.measure(line)
        return [""] if line_width.zero?

        start_column = 0
        out = []
        while start_column < line_width
          out << UI.visible_slice(line, start_column, width)
          start_column += width
        end
        out
      end

      # Returns the rendered content string, calling `render.to_s` on the content object when
      # it responds to render.
      def rendered_content
        content.respond_to?(:render) ? content.render.to_s : content.to_s
      end

      # Returns the visible row count (the configured *height* or the content's line count).
      def viewport_height
        height || content_lines.length
      end

      # Returns the number of rows to advance on a page up/down: at least 1, otherwise the
      # viewport height.
      def page_size
        [viewport_height, 1].max
      end

      # Returns the maximum allowed row offset (so the bottom of the content is reachable).
      def max_offset
        [content_lines.length - viewport_height, 0].max
      end

      # Returns the maximum allowed column offset. Returns 0 when wrapping is enabled or
      # when no width is configured.
      def max_column
        return 0 if wrap?
        return 0 unless width

        [content_width - width, 0].max
      end

      # Returns the maximum display width across all content lines.
      def content_width
        content_lines.map { |line| UI::Width.measure(line) }.max || 0
      end

      # True when *token* is an ANSI escape sequence.
      def ansi?(token)
        token.match?(ANSI_PATTERN)
      end

      # True when soft-wrapping is enabled and a positive width is configured.
      def wrap?
        @wrap && width&.positive?
      end
    end
  end
end
