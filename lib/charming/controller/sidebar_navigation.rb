# frozen_string_literal: true

module Charming
  class Controller
    # Sidebar-navigation helpers mixed into Controller. Tracks the sidebar's current route index,
    # routes j/k/enter/tab keys when the sidebar is focused, and exposes `sidebar_focused?` for views.
    module SidebarNavigation
      # Moves focus to the sidebar. When the controller declared a focus ring, the focus object
      # is updated; otherwise a fallback session key tracks focus.
      def focus_sidebar
        if focus_ring_slot?(:sidebar)
          focus.focus(:sidebar)
        else
          session[:focus] = :sidebar
        end
        session[:sidebar_index] ||= current_route_index
        render_default_action
      end

      # Moves focus to the content pane (the inverse of `focus_sidebar`).
      def focus_content
        if focus_ring_slot?(:content)
          focus.focus(:content)
        else
          session[:focus] = :content
        end
        render_default_action
      end

      # True when the sidebar is the current focus target. Uses the focus ring when defined.
      def sidebar_focused?
        return focused?(:sidebar) if focus_ring_slot?(:sidebar)

        session[:focus] == :sidebar
      end

      # True when the content pane is the current focus target. Uses the focus ring when defined.
      def content_focused?
        return focused?(:content) if focus_ring_slot?(:content)

        session[:focus] == :content
      end

      # Returns the index of the currently selected route in `sidebar_routes`, defaulting to the
      # active route when the session index is unset.
      def sidebar_index
        session[:sidebar_index] || current_route_index
      end

      # Returns all routes from the application's router, in registration order.
      def sidebar_routes
        application.routes.all
      end

      # True when *candidate* route matches the controller's currently active route (used to
      # highlight the current row in the sidebar).
      def current_route?(candidate)
        return candidate.controller_class == self.class && candidate.action == :show unless route

        candidate.path == route.path &&
          candidate.controller_class == route.controller_class &&
          candidate.action == route.action
      end

      private

      # Returns the index of the route that matches `current_route?`, defaulting to 0.
      def current_route_index
        sidebar_routes.index { |candidate| current_route?(candidate) } || 0
      end

      # Dispatches j/k/enter/tab/escape to sidebar movement and selection; falls through to
      # a default render for any other key.
      def dispatch_sidebar_key
        case key_name
        when :j, :down then sidebar_move(+1)
        when :k, :up then sidebar_move(-1)
        when :enter then sidebar_select
        when :escape, :tab then focus_content
        else render_default_action
        end
        response
      end

      # Mouse dispatch for the sidebar. Reserved for future use; returns nil.
      def dispatch_sidebar_mouse
        nil
      end

      # Moves the sidebar cursor by *delta* positions, clamped to the route list bounds.
      def sidebar_move(delta)
        count = sidebar_routes.length
        return render_default_action if count.zero?

        session[:sidebar_index] = (sidebar_index + delta).clamp(0, count - 1)
        render_default_action
      end

      # Selects the route currently highlighted in the sidebar and navigates to it.
      def sidebar_select
        route = sidebar_routes[sidebar_index]
        if focus_ring_slot?(:content)
          focus.focus(:content)
        else
          session[:focus] = :content
        end
        route ? navigate_to(route.path) : render_default_action
      end
    end
  end
end
