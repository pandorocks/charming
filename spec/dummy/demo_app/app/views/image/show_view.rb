# frozen_string_literal: true

module DemoApp
  module Image
    # Renders the sample image inline via the Kitty graphics protocol (Ghostty/Kitty). On terminals
    # without graphics support, the component renders the fallback text instead.
    class ShowView < Charming::View
      def render
        column(title_line, image_block, caption_line, gap: 1)
      end

      private

      def title_line
        text "Image Component", style: theme.title
      end

      def image_block
        render_component(Charming::Components::Image.new(
          source: assigns.fetch(:image),
          rows: 15,
          cols: 44,
          fallback: fallback_text,
          theme: theme
        ))
      end

      def fallback_text
        text "[ this terminal has no graphics protocol — try Ghostty or Kitty ]", style: theme.warn
      end

      def caption_line
        text "dusk-guardian.png via the Kitty graphics protocol. c copies the path + notifies, q quits.", style: theme.muted
      end
    end
  end
end
