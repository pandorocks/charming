# frozen_string_literal: true

module Charming
  module Presentation
    module Layout
      class Builder
        def self.build(screen:, view:, background: nil, &)
          new(screen: screen, view: view, background: background).build(&)
        end

        def initialize(screen:, view:, background: nil)
          @view = view
          @root = ScreenLayout.new(screen: screen, background: background)
          @stack = [@root]
        end

        def build(&)
          instance_eval(&) if block_given?
          root
        end

        def split(direction, gap: 0, **options, &)
          node = Split.new(direction: direction, gap: gap, **options)
          append(node)
          within(node, &)
          node
        end

        def pane(name = nil, content = nil, **options, &block)
          node = Pane.new(name: name, content: content, block: block, view: view, **options)
          append(node)
          node
        end

        def overlay(content = nil, top: :center, left: :center, **options, &block)
          root.add_overlay(Overlay.new(content: content, block: block, view: view, top: top, left: left, **options))
        end

        def respond_to_missing?(name, include_private = false)
          view.respond_to?(name, include_private) || super
        end

        def method_missing(name, ...)
          return view.__send__(name, ...) if view.respond_to?(name, true)

          super
        end

        private

        attr_reader :root, :stack, :view

        def append(node)
          stack.last.add_child(node)
        end

        def within(node, &)
          return unless block_given?

          stack.push(node)
          instance_eval(&)
        ensure
          stack.pop
        end
      end
    end
  end
end
