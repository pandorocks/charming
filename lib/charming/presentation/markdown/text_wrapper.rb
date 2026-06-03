# frozen_string_literal: true

module Charming
  module Markdown
    # TextWrapper wraps Markdown text blocks to a configured terminal width.
    class TextWrapper
      def initialize(width:)
        @width = width
      end

      def wrap(value)
        return value unless width

        value.to_s.lines(chomp: true).map { |line| wrap_line(line) }.join("\n")
      end

      private

      attr_reader :width

      def wrap_line(line)
        return line if UI::Width.measure(line) <= width

        wrap_words(line.split(/\s+/))
      end

      def wrap_words(words)
        words.each_with_object([]) { |word, lines| append_word(lines, word) }.join("\n")
      end

      def append_word(lines, word)
        current = lines.pop.to_s
        candidate = current.empty? ? word : "#{current} #{word}"
        return lines.push(candidate) if current.empty? || UI::Width.measure(candidate) <= width

        lines.push(current.rstrip, word)
      end
    end
  end
end
