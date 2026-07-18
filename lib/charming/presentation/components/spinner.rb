# frozen_string_literal: true

module Charming
  module Components
    # Spinner is a simple rotating-frame indicator. The component cycles through a list of
    # frames on each `tick`; pair it with a controller timer to drive animation. An optional
    # *label* is appended after the current frame on each render.
    class Spinner < Component
      # The default frame set: a 4-frame ASCII spinner.
      DEFAULT_FRAMES = ["-", "\\", "|", "/"].freeze

      # Named frame presets, mirroring the roster popularized by charm.sh's bubbles.
      STYLES = {
        line: DEFAULT_FRAMES,
        dots: %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze,
        mini_dot: %w[⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈].freeze,
        jump: %w[⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠].freeze,
        pulse: %w[█ ▓ ▒ ░].freeze,
        points: ["∙∙∙", "●∙∙", "∙●∙", "∙∙●"].freeze,
        globe: %w[🌍 🌎 🌏].freeze,
        moon: %w[🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘].freeze,
        meter: %w[▱▱▱ ▰▱▱ ▰▰▱ ▰▰▰ ▰▰▱ ▰▱▱].freeze,
        hamburger: %w[☱ ☲ ☴ ☲].freeze,
        ellipsis: ["   ", ".  ", ".. ", "..."].freeze
      }.freeze

      # The current frame list, frame index, and optional label string.
      attr_reader :frames, :index, :label

      # *style* picks a named preset from STYLES (default :line). *frames* overrides the
      # preset with any array of frame strings. *index* is the starting frame index.
      # *label* is an optional suffix shown after the frame.
      def initialize(style: :line, frames: nil, index: 0, label: nil)
        super()
        frames ||= STYLES.fetch(style.to_sym) do
          raise ArgumentError, "unknown spinner style: #{style.inspect} (available: #{STYLES.keys.join(", ")})"
        end
        raise ArgumentError, "frames cannot be empty" if frames.empty?

        @frames = frames
        @index = index
        @label = label
      end

      # Advances the frame index by one position, wrapping around. Returns self for chaining.
      def tick
        @index = (index + 1) % frames.length
        self
      end

      # Renders the current frame, optionally followed by the label and a space.
      def render
        return frame unless label

        "#{frame} #{label}"
      end

      private

      # Returns the current frame string (with index modulo frame count to be safe).
      def frame
        frames.fetch(index % frames.length)
      end
    end
  end
end
