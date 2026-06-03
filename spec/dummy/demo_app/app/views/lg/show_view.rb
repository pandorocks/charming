# frozen_string_literal: true

module DemoApp
  module Lg
    class ShowView < Charming::View
      def render
        screen_layout(background: theme.background) do
          split :vertical, gap: 1 do
            pane(:header, height: 3, border: :rounded, padding: [0, 2], style: theme.title) do
              header
            end

            split :vertical, grow: 1, gap: 1 do
              split :horizontal, height: 9, gap: 1 do
                pane(:status, width: 32, border: :rounded, padding: [1, 2], style: theme.border, focus: true) do
                  status_panel
                end

                pane(:commits, grow: 1, border: :rounded, padding: [1, 2], style: theme.border, focus: true) do
                  commits_panel
                end
              end

              split :horizontal, grow: 1, gap: 1 do
                pane(:files, width: 32, border: :rounded, padding: [1, 2], style: theme.border, focus: true) do
                  files_panel
                end

                pane(:diff, grow: 1, border: :rounded, padding: [1, 2], style: theme.border, focus: true, wrap: true) do
                  diff_panel
                end
              end
            end

            pane(:help, height: 3, border: :rounded, padding: [0, 2], style: theme.border) do
              help_panel
            end
          end

          overlay command_palette_modal if command_palette_modal
        end
      end

      private

      def header
        row(
          text("charming", style: theme.header_accent.bold),
          text("main", style: theme.info),
          text("2 ahead, 1 behind", style: theme.warn),
          gap: 3
        )
      end

      def status_panel
        column(
          text("Working Tree", style: theme.title),
          text("2 staged", style: theme.info),
          text("4 unstaged", style: theme.warn),
          text("1 untracked", style: theme.muted),
          gap: 0
        )
      end

      def files_panel
        column(
          text("Files", style: theme.title),
          text("M  lib/charming/presentation/layout/pane.rb", style: theme.info),
          text("M  spec/dummy/demo_app/app/views/lg/show_view.rb", style: theme.info),
          text("A  docs/layouts.md", style: theme.muted),
          text("?? notes/layout-sketch.md", style: theme.warn),
          gap: 0
        )
      end

      def commits_panel
        column(
          text("Recent Commits", style: theme.title),
          text("a8f31c2 Add declarative layout panes", style: theme.text),
          text("74db201 Prefer Ruby view classes", style: theme.text),
          text("2bb09ea Keep ERB as fallback", style: theme.text),
          text("0fd11a4 Add terminal mouse events", style: theme.text),
          gap: 0
        )
      end

      def diff_panel
        column(
          text("Diff", style: theme.title),
          text("diff --git a/app/views/lg/show_view.rb b/app/views/lg/show_view.rb", style: theme.muted),
          text("+ screen_layout(background: theme.background) do", style: theme.info),
          text("+   split :horizontal, grow: 1, gap: 1 do", style: theme.info),
          text("+     pane(:diff, grow: 1, border: :rounded, wrap: true) { diff_panel }", style: theme.info),
          text("- manual_width = screen.width - sidebar_width - 3", style: theme.warn),
          gap: 0
        )
      end

      def help_panel
        row(
          text("tab focus", style: theme.muted),
          text("ctrl+p commands", style: theme.muted),
          text("q quit", style: theme.muted),
          text("/ filter", style: theme.muted),
          gap: 3
        )
      end

      def command_palette_modal
        return unless palette

        render_component Charming::Components::Modal.new(
          content: palette,
          title: "Command palette",
          help: "Type to filter. Enter selects. Escape closes.",
          width: 52,
          theme: theme
        )
      end

      def palette
        assigns.fetch(:palette, nil)
      end
    end
  end
end
