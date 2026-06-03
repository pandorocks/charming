# frozen_string_literal: true

module Charming
  module Internal
    module Renderer
      # Differential renders frame updates by emitting only the lines that changed since
      # the previous frame. On the first frame it falls back to a full repaint; when no
      # lines changed it returns without writing anything.
      class Differential
        # *output* is the terminal backend (must support `write_lines` for the differential
        # path or `write_frame` for the fallback). *full_renderer* is the FullRepaint used
        # for the initial frame and as a fallback when *output* doesn't support partial writes.
        def initialize(output, full_renderer: FullRepaint.new(output))
          @output = output
          @full_renderer = full_renderer
          @previous_frame = nil
        end

        # Renders *frame*. The first call performs a full repaint and stores the frame.
        # Subsequent calls compute the per-line diff and emit only changed rows. Returns nil
        # when the frame is identical to the previous one.
        def render(frame)
          frame = frame.to_s
          return render_initial(frame) unless @previous_frame
          return if frame == @previous_frame

          render_changes(frame)
        end

        # Discards the cached previous frame so the next render performs a full repaint.
        # Call this when the screen contents are no longer trustworthy (e.g. terminal resize).
        def invalidate
          @previous_frame = nil
        end

        private

        # Performs the initial full repaint and records the first frame.
        def render_initial(frame)
          @full_renderer.render(frame)
          @previous_frame = frame
        end

        # Computes the per-line diff against the previous frame, writes only changed lines,
        # and records the new frame. Falls back to a full repaint when the output backend
        # doesn't support partial writes.
        def render_changes(frame)
          changes = changed_lines(@previous_frame, frame)
          return @previous_frame = frame if changes.empty?

          if @output.respond_to?(:write_lines)
            @output.write_lines(changes, frame: frame)
          else
            @full_renderer.render(frame)
          end
          @previous_frame = frame
        end

        # Returns an array of [1-based-row, line] tuples for rows whose content changed.
        # Empty strings clear rows that existed in the previous frame but not the new one.
        def changed_lines(previous_frame, frame)
          previous_lines = previous_frame.lines(chomp: true)
          lines = frame.lines(chomp: true)
          line_count = [previous_lines.length, lines.length].max

          line_count.times.filter_map do |index|
            line = lines[index] || ""
            previous_line = previous_lines[index] || ""
            [index + 1, line] unless line == previous_line
          end
        end
      end
    end
  end
end
