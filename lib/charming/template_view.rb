# frozen_string_literal: true

module Charming
  class TemplateView < View
    def initialize(template:, namespace: nil, **assigns)
      super(**assigns)
      @template = template
      @namespace = namespace
    end

    def render
      template.render(self).to_s
    end

    def template_binding
      return binding unless namespace

      namespace.module_eval("->(view) { view.instance_eval { binding } }", __FILE__, __LINE__).call(self)
    end

    private

    attr_reader :template, :namespace
  end
end
