# frozen_string_literal: true

module Charming
  class Controller
    module SidebarNavigation
      def focus_sidebar
        if focus_ring_slot?(:sidebar)
          focus.focus(:sidebar)
        else
          session[:focus] = :sidebar
        end
        session[:sidebar_index] ||= current_route_index
        render_default_action
      end

      def focus_content
        if focus_ring_slot?(:content)
          focus.focus(:content)
        else
          session[:focus] = :content
        end
        render_default_action
      end

      def sidebar_focused?
        return focused?(:sidebar) if focus_ring_slot?(:sidebar)

        session[:focus] == :sidebar
      end

      def content_focused?
        return focused?(:content) if focus_ring_slot?(:content)

        session[:focus] == :content
      end

      def sidebar_index
        session[:sidebar_index] || current_route_index
      end

      def sidebar_routes
        application.routes.all
      end

      def current_route?(candidate)
        return candidate.controller_class == self.class && candidate.action == :show unless route

        candidate.path == route.path &&
          candidate.controller_class == route.controller_class &&
          candidate.action == route.action
      end

      private

      def current_route_index
        sidebar_routes.index { |candidate| current_route?(candidate) } || 0
      end

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

      def dispatch_sidebar_mouse
        nil
      end

      def sidebar_move(delta)
        count = sidebar_routes.length
        return render_default_action if count.zero?

        session[:sidebar_index] = (sidebar_index + delta).clamp(0, count - 1)
        render_default_action
      end

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
