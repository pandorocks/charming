# frozen_string_literal: true

module Charming
  module Layout
    # Builder turns a declarative `screen_layout { ... }` block into a layout tree of
    # ScreenLayout → Split → Pane nodes. The block DSL is `split(direction) { ... }`,
    # `pane(name) { ... }`, and `overlay { ... }`. Unknown method calls in the block are
    # forwarded to the underlying view so view helpers (e.g., `text`) work inside layout blocks.
    class Builder
      # Builds the layout tree by evaluating the *block* in the builder's context.
      # Returns the root ScreenLayout node.
      def self.build(screen:, view:, background: nil, &)
        new(screen: screen, view: view, background: background).build(&)
      end

      def initialize(screen:, view:, background: nil)
        @view = view
        @root = ScreenLayout.new(screen: screen, background: background)
        @stack = [@root]
      end

      # Evaluates *block* in the builder's context, then returns the root ScreenLayout node.
      def build(&)
        instance_eval(&) if block_given?
        root
      end

      # Adds a Split node to the current scope. *direction* is `:horizontal` or `:vertical`.
      # *gap* (in cells) is inserted between children. Additional *options* are forwarded
      # to Split. The block, if given, is evaluated in the split's scope (for nested children).
      def split(direction, gap: 0, **options, &)
        node = Split.new(direction: direction, gap: gap, **options)
        append(node)
        within(node, &)
        node
      end

      # Adds a Pane leaf node to the current scope. *name* (optional) is the focus slot name;
      # *content* (or a *block*) is the body. *options* are forwarded to Pane.
      def pane(name = nil, content = nil, **options, &block)
        node = Pane.new(name: name, content: content, block: block, view: view, **options)
        append(node)
        node
      end

      # Adds an Overlay node to the root ScreenLayout. *top* and *left* default to :center.
      # The block, if given, is evaluated in the view's context.
      def overlay(content = nil, top: :center, left: :center, **options, &block)
        root.add_overlay(Overlay.new(content: content, block: block, view: view, top: top, left: left, **options))
      end

      # Forwards unknown method calls to the underlying view so helpers like `text` work
      # inside layout blocks.
      def respond_to_missing?(name, include_private = false)
        view.respond_to?(name, include_private) || super
      end

      def method_missing(name, ...)
        return view.__send__(name, ...) if view.respond_to?(name, true)

        super
      end

      private

      attr_reader :root, :stack, :view

      # Appends *node* to the topmost scope on the stack.
      def append(node)
        stack.last.add_child(node)
      end

      # Pushes *node* onto the stack, evaluates *block* in the builder's context, then pops it.
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
