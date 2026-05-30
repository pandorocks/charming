# frozen_string_literal: true

module Charming
  class Focus
    def self.for(session, controller_class)
      session[:focus_state] ||= {}
      key = controller_class.name
      session[:focus_state][key] ||= { scopes: [] }
      new(session[:focus_state][key])
    end

    def initialize(state)
      @state = state
    end

    def define(slots)
      return if @state[:scopes].any? { |scope| scope[:origin] == :ring }

      @state[:scopes] << build_scope(slots, :ring)
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

    def build_scope(slots, origin)
      { ring: slots.dup.freeze, current: slots.first, origin: origin }
    end
  end
end
