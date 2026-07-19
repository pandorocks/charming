# frozen_string_literal: true

module Charming
  module Welcome
    # Controller for the built-in welcome screen. Renders without an app layout and
    # binds only `q` to quit.
    class Controller < Charming::Controller
      key "q", :quit, scope: :global

      def show
        render_view ShowView, app_name: app_display_name
      end

      private

      # The app's namespace for the welcome heading, or "Charming" for anonymous apps.
      def app_display_name
        name = application.class.namespace
        name.to_s.empty? ? "Charming" : name
      end
    end
  end
end
