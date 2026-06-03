# frozen_string_literal: true

module Charming
  class Controller
    # Focus manages a stack of focus scopes (rings) for a single controller class. Each scope has
    # a slot ring (a fixed list of named slots) and a current slot within that ring. Multiple
    # scopes can be stacked so the command palette, modals, and layouts can each have their own
    # focus contexts without interfering with one another.
    #
    # State lives under `session[:focus_state][controller_class_name]` so focus persists across
    # controller dispatches within the same session.
    class Focus
      # Returns the Focus object for *controller_class* under the given *session*, creating the
      # underlying session hash if absent.
      def self.for(session, controller_class)
        session[:focus_state] ||= {}
        key = controller_class.name
        session[:focus_state][key] ||= {scopes: []}
        new(session[:focus_state][key])
      end

      def initialize(state)
        @state = state
      end

      # Defines the primary focus ring for the controller with the given *slots*. Only effective
      # the first time it is called; subsequent calls are no-ops.
      def define(slots)
        return if @state[:scopes].any? { |scope| scope[:origin] == :ring }

        @state[:scopes] << build_scope(slots, :ring)
      end

      # Defines a layout scope (inserted after the primary ring and before modal scopes). *slots*
      # is the list of pane names; the previously-focused layout slot is preserved when it is still
      # part of the new ring.
      def define_layout(slots)
        current = current_layout_slot(slots)
        remove_scope(:layout)
        return if slots.empty?

        @state[:scopes].insert(layout_scope_index, build_scope(slots, :layout, current))
      end

      # Pushes a new focus scope with the given *slots* onto the stack. Used by modals, palettes,
      # and other overlays. *origin* is a label for the scope kind.
      def push_scope(slots, origin: :modal)
        @state[:scopes] << build_scope(slots, origin)
      end

      # Pops the topmost focus scope from the stack.
      def pop_scope
        @state[:scopes].pop
      end

      # Returns the currently focused slot, or nil when no scope is active.
      def current
        top && top[:current]
      end

      # Returns the slot ring of the topmost scope (an array of slot names). Empty when no scope.
      def ring
        top ? top[:ring] : []
      end

      # Sets the current slot within the topmost scope to *slot*. No-op when *slot* is not in the ring.
      def focus(slot)
        return unless ring.include?(slot)

        top[:current] = slot
      end

      # Cycles focus by *direction* (default +1 forward) within the topmost ring. No-op on an empty ring.
      def cycle(direction = +1)
        return if ring.empty?

        index = ring.index(current) || 0
        top[:current] = ring[(index + direction) % ring.length]
      end

      # True when *slot* is the current focus slot.
      def focused?(slot)
        current == slot
      end

      private

      # Returns the topmost scope hash (the last entry pushed onto `@state[:scopes]`).
      def top
        @state[:scopes].last
      end

      # Removes every scope whose origin equals *origin* (in place).
      def remove_scope(origin)
        @state[:scopes].reject! { |scope| scope[:origin] == origin }
      end

      # Returns the index in the scope stack where a layout scope belongs: just before the first
      # non-ring, non-layout scope (i.e., at the end of the "structural" stack).
      def layout_scope_index
        index = @state[:scopes].index { |scope| !%i[ring layout].include?(scope[:origin]) }
        index || @state[:scopes].length
      end

      # Returns the current layout scope's current slot, but only when it is still part of *slots*.
      # Otherwise returns the first slot in *slots* (so a new layout reverts to its first pane).
      def current_layout_slot(slots)
        current_slot = current_layout_scope&.fetch(:current)
        slots.include?(current_slot) ? current_slot : slots.first
      end

      # Returns the layout scope, or nil when no layout scope is present.
      def current_layout_scope
        @state[:scopes].find { |scope| scope[:origin] == :layout }
      end

      # Builds an immutable scope hash with the given *slots*, *origin*, and starting *current* slot.
      def build_scope(slots, origin, current = slots.first)
        {ring: slots.dup.freeze, current: current, origin: origin}
      end
    end
  end
end
