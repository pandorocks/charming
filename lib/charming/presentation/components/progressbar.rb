# frozen_string_literal: true

module Charming
  module Components
    # Progressbar renders a fixed-width ASCII progress bar. The bar is sized to the configured
    # *total* (in arbitrary units) and fills proportionally to the current value. Optionally
    # appends a label after the bar.
    class Progressbar < Component
      # Public accessors: total units, current value, label text, completed and remaining
      # characters, and the bar format symbol.
      attr_accessor :total, :current, :label, :complete, :incomplete, :bar_format

      # *total* is the maximum unit count. *complete* and *incomplete* are the characters used
      # for filled and unfilled positions (default "=" and " "). *bar_format* is reserved for
      # future format variants. *label* is an optional suffix shown after the bar.
      def initialize(total:, complete: "=", incomplete: " ", bar_format: :classic, label: nil)
        super()
        @total = [total.to_i, 0].max
        @complete = complete.to_s
        @incomplete = incomplete.to_s
        @bar_format = bar_format.to_sym
        @label = label
        @current = 0
      end

      # Advances the current value by *count* (default 1), clamping to `[0, total]`. Returns self.
      def tick(count = 1)
        update(@current + count)
        self
      end

      # Sets the current value, clamping to `[0, total]`. Returns self.
      def update(value)
        @current = value.to_i.clamp(0, @total)
        self
      end

      # Jumps the bar directly to 100% completion. Returns self.
      def complete!
        @current = @total
        self
      end

      # Renders the bar as `[====  ]` (with the *label* appended when present).
      def render
        width = [@total, 1].max
        completed = completed_width(width)
        incomplete = width - completed
        bar = (@complete * completed) + (@incomplete * incomplete)
        result = "[" + bar + "]"

        return result unless @label

        "#{result} #{@label}"
      end

      private

      # Returns the number of `complete` characters to draw, rounded to the nearest integer.
      def completed_width(width)
        return 0 unless @total.positive?

        ((width * @current) / @total.to_f).round
      end
    end
  end
end
