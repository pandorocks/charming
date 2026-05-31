# frozen_string_literal: true

module Charming
  module Components
    class Progressbar < Component
      attr_accessor :total, :current, :label, :complete, :incomplete, :bar_format

      def initialize(total:, complete: "=", incomplete: " ", bar_format: :classic, label: nil)
        super()
        @total = [total.to_i, 0].max
        @complete = complete.to_s
        @incomplete = incomplete.to_s
        @bar_format = bar_format.to_sym
        @label = label
        @current = 0
      end

      def tick(count = 1)
        update(@current + count)
        self
      end

      def update(value)
        @current = value.to_i.clamp(0, @total)
        self
      end

      def complete!
        @current = @total
        self
      end

      def render
        width = [@total, 1].max
        completed = completed_width(width)
        incomplete = width - completed
        incomplete -= 1 if @current.zero?
        bar = (@complete * completed) + (@incomplete * incomplete)
        result = "[" + bar + "]"

        return result unless @label

        "#{result} #{@label}"
      end

      private

      def completed_width(width)
        return 0 unless @total.positive?

        ((width * @current) / @total.to_f).round
      end
    end
  end
end
