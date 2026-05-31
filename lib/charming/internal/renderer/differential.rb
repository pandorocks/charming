# frozen_string_literal: true

module Charming
  module Internal
    module Renderer
      class Differential
        def initialize(output, full_renderer: FullRepaint.new(output))
          @output = output
          @full_renderer = full_renderer
          @previous_frame = nil
        end

        def render(frame)
          frame = frame.to_s
          return render_initial(frame) unless @previous_frame
          return if frame == @previous_frame

          render_changes(frame)
        end

        private

        def render_initial(frame)
          @full_renderer.render(frame)
          @previous_frame = frame
        end

        def render_changes(frame)
          changes = changed_suffix(@previous_frame, frame)
          return @previous_frame = frame if changes.empty?

          if @output.respond_to?(:write_lines)
            @output.write_lines(changes, frame: frame)
          else
            @full_renderer.render(frame)
          end
          @previous_frame = frame
        end

        def changed_suffix(previous_frame, frame)
          previous_lines = previous_frame.lines(chomp: true)
          lines = frame.lines(chomp: true)
          line_count = [previous_lines.length, lines.length].max
          first_changed_index = line_count.times.find { |index| previous_lines[index] != lines[index] }
          return [] unless first_changed_index

          first_changed_index.upto(line_count - 1).map do |index|
            [index + 1, lines[index] || ""]
          end
        end
      end
    end
  end
end
