# frozen_string_literal: true

module Charming
  class View
    def initialize(**assigns)
      @assigns = assigns
      define_assign_readers
    end

    def layout_assigns
      assigns
    end

    def render
      ""
    end

    private

    attr_reader :assigns

    def style
      UI.style
    end

    def text(value, style: nil)
      rendered = apply_style(value.to_s, style)
      append_to_buffer(rendered)
      rendered
    end

    def box(value = nil, style: nil, &)
      content = block_given? ? capture(&) : value.to_s
      apply_style(content, style)
    end

    def row(*items, gap: 0)
      UI.join_horizontal(*items, gap: gap)
    end

    def column(*items, gap: 0)
      UI.join_vertical(*items, gap: gap)
    end

    def render_component(component)
      component.render.to_s
    end

    def render_partial(partial)
      render_component(partial)
    end

    def yield_content
      assigns.fetch(:content, "")
    end

    def capture(&)
      previous_buffer = @output_buffer
      @output_buffer = []
      result = instance_eval(&)
      @output_buffer.empty? ? result.to_s : @output_buffer.join("\n")
    ensure
      @output_buffer = previous_buffer
    end

    def append_to_buffer(value)
      @output_buffer << value if @output_buffer
    end

    def apply_style(value, style_object)
      style_object ? style_object.render(value) : value
    end

    def define_assign_readers
      assigns.each_key do |name|
        next if respond_to?(name, true)

        define_singleton_method(name) { assigns.fetch(name) }
      end
    end
  end
end
