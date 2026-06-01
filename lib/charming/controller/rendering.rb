# frozen_string_literal: true

module Charming
  class Controller
    module Rendering
      private

      def render_body(body)
        body.respond_to?(:render) ? body.render.to_s : body.to_s
      end

      def render_with_layout(body)
        rendered = render_body(body)
        layout = self.class.layout
        return rendered unless layout

        render_body(layout_body(layout, body, rendered))
      end

      def layout_body(layout, body, rendered)
        assigns = layout_assigns(body, rendered)
        return template_body(layout, **assigns) if layout.is_a?(String) || layout.is_a?(Symbol)

        layout.new(**assigns)
      end

      def layout_assigns(body, rendered)
        view_assigns(body).merge(content: rendered, screen: screen, controller: self, theme: theme)
      end

      def view_assigns(body)
        body.respond_to?(:layout_assigns) ? body.layout_assigns : {}
      end

      def template_body(name, **assigns)
        Presentation::TemplateView.new(template: resolve_template(name), namespace: template_namespace, **template_assigns(assigns))
      end

      def resolve_template(name)
        Presentation::Templates.resolve(name, root: application.class.root)
      end

      def template_assigns(assigns)
        {screen: screen, controller: self, theme: theme}.merge(assigns)
      end

      def template_namespace
        namespace_name = application.class.namespace
        return nil if namespace_name.to_s.empty?

        Object.const_get(namespace_name)
      end

      def default_template_name(action)
        "#{controller_template_path}/#{action}"
      end

      def controller_template_path
        underscore(self.class.name.split("::").last.delete_suffix("Controller"))
      end

      def underscore(value)
        value
          .gsub(/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
          .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
          .tr("-", "_")
          .downcase
      end
    end
  end
end
