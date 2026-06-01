# frozen_string_literal: true

module Charming
  module Presentation
    # TemplateView wraps a resolved ERB template and exposes it as a renderable View. The
    # template is rendered with the view's helpers (`text`, `box`, `row`, `column`, `style`,
    # `theme`, etc.) and the view's assigns available as reader methods inside the template.
    class TemplateView < View
      def initialize(template:, namespace: nil, **assigns)
        super(**assigns)
        @template = template
        @namespace = namespace
      end

      # Renders the wrapped template to a string, evaluated in the view's binding context.
      def render
        template.render(self).to_s
      end

      # Returns the binding used by ERB handlers to evaluate the template body. When *namespace*
      # is set, the binding is created by a proc generated in the namespace's context so the
      # template can resolve constants relative to the application.
      def template_binding
        return binding unless namespace

        namespace.module_eval("->(view) { view.instance_eval { binding } }", __FILE__, __LINE__).call(self)
      end

      private

      attr_reader :template, :namespace
    end
  end
end
