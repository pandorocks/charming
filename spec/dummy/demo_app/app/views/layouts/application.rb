# frozen_string_literal: true

module DemoApp
  module Layouts
    class Application < Charming::View
      # Renders the full application screen: an app-frame container (sidebar + main content) positioned
      # within the terminal, then overlays a command-palette modal when `palette` is present (command
      # palette open). The frame uses responsive width detection — horizontal row layout for wide screens
      # (>= 72 cols), vertical column stack for narrow ones. Returns a multiline styled string.
      def render
        body = Charming::UI.place(app_frame, width: screen.width, height: screen.height)
        return body unless palette

        Charming::UI.overlay(body, command_palette_modal)
      end

      private

      # Chooses between horizontal row or vertical column layout based on screen width.
      # When screen is <= 72 columns and >= 20 rows tall, stacks side-by-side vertically
      # using `column()`; otherwise places sidebar and main content horizontally via `row()`.
      # The two panels are always separated by a gap of 1 cell for visual breathing room.
      def app_frame
        narrow? ? column(sidebar, main_content, gap: 1) : row(sidebar, main_content, gap: 1)
      end

      # The left sidebar panel: a vertically stacked box containing the "DemoApp" title
      # header, route navigation list, and keyboard shortcuts hint text at the bottom.
      # All wrapped in a rounded-border box whose style adapts to focus state (title color
      # when focused, border color when not) with width constrained to `sidebar_width` and
      # height to `panel_height`. Returns a styled box string.
      def sidebar
        box(column(app_title, navigation, shortcuts, gap: 1), style: sidebar_style)
      end

      # The right content panel: a rounded-border box wrapping whatever each controller's
      # screen renders via `yield_content`. Injects the action body (e.g., home screen,
      # about screen) into this slot so the layout provides consistent framing across all
      # routes. Returns a styled box string displaying the current route's content.
      def main_content
        box(yield_content, style: main_content_style)
      end

      # Displays "DemoApp" centered in the sidebar header row using theme accent color.
      # Width-constrained to `sidebar_width` and text-aligned center for padding.
      def app_title
        text "DemoApp", style: theme.header_accent.align(:center).width(sidebar_width)
      end

      # Builds the navigation column from all registered application routes. Each route
      # renders as a text line via `nav_label` with appropriate styling via `nav_style`.
      # Stacks these rows vertically in a single column widget.
      def navigation
        column(*nav_items)
      end

      # Maps each registered route to its styled display text: iterates over
      # `controller.application.routes.all` and for each route produces a text row
      # showing the nav label (with cursor/active indicators) in the current route's style.
      def nav_items
        controller.application.routes.all.each_with_index.map do |route, index|
          text nav_label(route, index), style: nav_style(route, index)
        end
      end

      # Builds the navigation label string for a given route: prefixes with ">" when that
      # route's sidebar item is focused (sidebar_focused? && index == sidebar_index), otherwise " ".
      # Followed by "O" when this route is the current active route, then space and the route title.
      # Example output: "> O Home" for selected/active route, "   About" for inactive one.
      def nav_label(route, index)
        cursor = (sidebar_focused? && index == sidebar_index) ? ">" : " "
        active = current_route?(route) ? "\u{25cf}" : " "
        "#{cursor} #{active} #{route.title}"
      end

      # Returns the style for a navigation item based on selection state:
      # returns theme.selected when this sidebar row is focused, theme.title when
      # the route is currently active (but row unfocused), and theme.muted for all others.
      def nav_style(route, index)
        return theme.selected if sidebar_focused? && index == sidebar_index
        return theme.title if current_route?(route)

        theme.muted
      end

      # Displays keyboard shortcuts hint text in muted style: "Tab focus", "P commands",
      # "Q quit" shown across three lines at the bottom of the sidebar. Provides user
      # guidance for navigating the application's interactive features via keyboard input.
      def shortcuts
        text "tab focus\np commands\nq quit", style: theme.muted
      end

      # Delegates to controller.check which sidebar slot has focus (from focus ring or session stored value).
      # Returns true when sidebar selection navigation is currently active and keyboard events apply there.
      def sidebar_focused?
        controller.sidebar_focused?
      end

      # Delegates to controller#content_focused? checks whether the main body content area currently
      # has keyboard focus as opposed to the sidebar panel or command palette overlay widget.
      def content_focused?
        controller.content_focused?
      end

      # Returns the index of the currently highlighted sidebar navigation item from session
      # state managed by Controller#sidebar_index. Used for drawing the ">" cursor indicator
      # next to active sidebar entries in the rendered navigation column.
      def sidebar_index
        controller.sidebar_index
      end

      # Checks whether a given route is bound to the current controller's show action — i.e.,
      # whether it represents the active route on screen. Compares route controller_class and
      # :action against the current controller instance and its associated route definition.
      def current_route?(route)
        route.controller_class == controller.class && route.action == :show
      end

      # Renders a modal dialog overlay for the command palette UI, configured with title "Command
      # palette", help text describing input behaviors, 52-character width constraint, and theme.
      # Uses Charming::Components::Modal to produce centered floating window framing the fuzzy-search
      # command list component stored in session state as `palette` accessor on this view instance.
      def command_palette_modal
        render_component Charming::Components::Modal.new(
          content: palette,
          title: "Command palette",
          help: "Type to filter. Enter selects. Escape closes.",
          width: 52,
          theme: theme
        )
      end

      # Computes the sidebar box style: when sidebar is focused uses theme.title color,
      # otherwise theme.border for inactive appearance. Wraps in rounded borders with 1x2
      # padding sized to `sidebar_width` and `panel_height`. Applies .faint dimming effect
      # when command palette modal overlay is shown (reduces visual focus on inactive panel).
      def sidebar_style
        base = sidebar_focused? ? theme.title : theme.border
        base = base.border(:rounded).padding(1, 2).width(sidebar_width).height(panel_height)
        palette ? base.faint : base
      end

      # Computes the main content box style mirroring sidebar logic: uses theme.title when
      # content area focused, theme.border when not. Applies rounded borders with padding,
      # sizing to `main_content_width` height from `panel_height`. Faint dimming applied
      # when command palette is active so user focuses on overlay rather than background panel.
      def main_content_style
        base = content_focused? ? theme.title : theme.border
        base = base.border(:rounded).padding(1, 2).width(main_content_width).height(panel_height)
        palette ? base.faint : base
      end

      # Returns true when screen width is less than 72 columns AND height >= 20 rows — the
      # condition under which layout switches from horizontal row to vertical column. This
      # narrow mode prevents extremely thin side-by-side panels on constrained terminal windows.
      def narrow?
        screen.width < 72 && screen.height >= 20
      end

      # Returns sidebar width: fixed 22 characters when wide, otherwise dynamically calcualted as
      # screen_width minus 6 (content gap + right-panel padding) minimum of 20 columns. Prevents
      # collapsing below usable minimum even in very narrow terminal windows by enforcing a floor value.
      def sidebar_width
        narrow? ? [screen.width - 6, 20].max : 22
      end

      # Calculates main content width: when wide mode active, subtracts sidebar width (22) +
      # gap (1) + shortcuts column (~2) padding = 13 from total screen, takes minimum of 20.
      # In narrow mode same as sidebar — both columns get equal remaining screen space. This is
      # the horizontal breathing room available for content rendering inside the main panel box.
      def main_content_width
        narrow? ? [screen.width - 6, 20].max : [screen.width - sidebar_width - 13, 20].max
      end

      # Returns panel display height: nil when in narrow mode (let panels grow organically),
      # otherwise minimum of (screen.height - 4) and fixed 5 characters. The "-4" reserves top/bottom
      # terminal padding for command palette overlay positioning; ensures panels don't exceed content area.
      def panel_height
        return nil if narrow?

        [screen.height - 4, 5].max
      end
    end
  end
end
