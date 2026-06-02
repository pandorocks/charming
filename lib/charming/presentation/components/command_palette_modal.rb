# frozen_string_literal: true

module Charming
  module Presentation
    module Components
      # CommandPaletteModal wraps command palette content in the framework's standard modal chrome.
      class CommandPaletteModal < Component
        DEFAULT_TITLE = "Command palette"
        DEFAULT_HELP = "Type to filter. Enter selects. Escape closes."
        DEFAULT_WIDTH = 52

        def initialize(content:, title: DEFAULT_TITLE, help: DEFAULT_HELP, width: DEFAULT_WIDTH, style: nil, theme: nil)
          super(theme: theme)
          @content = content
          @title = title
          @help = help
          @width = width
          @style = style
        end

        def render
          render_component Modal.new(content: content, title: title, help: help, width: width, style: modal_style, theme: theme)
        end

        private

        attr_reader :content, :title, :help, :width

        def modal_style
          @style
        end
      end
    end
  end
end
