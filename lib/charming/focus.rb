# frozen_string_literal: true

module Charming
  class Focus
    def self.for(session, controller_class)
      session[:focus_state] ||= {}
      key = controller_class.name
      session[:focus_state][key] ||= {scopes: []}
      new(session[:focus_state][key])
    end

    def initialize(state)
      @state = state
    end

    def define(slots)
      return if @state[:scopes].any? { |scope| scope[:origin] == :ring }

      @state[:scopes] << build_scope(slots, :ring)
    end

    def define_layout(slots)
      current = current_layout_slot(slots)
      remove_scope(:layout)
      return if slots.empty?

      @state[:scopes].insert(layout_scope_index, build_scope(slots, :layout, current))
    end

    def push_scope(slots, origin: :modal)
      @state[:scopes] << build_scope(slots, origin)
    end

    def pop_scope
      @state[:scopes].pop
    end

    def current
      top && top[:current]
    end

    def ring
      top ? top[:ring] : []
    end

    def focus(slot)
      return unless ring.include?(slot)

      top[:current] = slot
    end

    def cycle(direction = +1)
      return if ring.empty?

      index = ring.index(current) || 0
      top[:current] = ring[(index + direction) % ring.length]
    end

    def focused?(slot)
      current == slot
    end

    private

    def top
      @state[:scopes].last
    end

    def remove_scope(origin)
      @state[:scopes].reject! { |scope| scope[:origin] == origin }
    end

    def layout_scope_index
      index = @state[:scopes].index { |scope| !%i[ring layout].include?(scope[:origin]) }
      index || @state[:scopes].length
    end

    def current_layout_slot(slots)
      current_slot = current_layout_scope&.fetch(:current)
      slots.include?(current_slot) ? current_slot : slots.first
    end

    def current_layout_scope
      @state[:scopes].find { |scope| scope[:origin] == :layout }
    end

    def build_scope(slots, origin, current = slots.first)
      {ring: slots.dup.freeze, current: current, origin: origin}
    end
  end
end
