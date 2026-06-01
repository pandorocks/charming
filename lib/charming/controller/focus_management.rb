# frozen_string_literal: true

module Charming
  class Controller
    module FocusManagement
      def focus
        @focus ||= Focus.for(session, self.class).tap do |f|
          f.define(self.class.focus_ring_slots) unless self.class.focus_ring_slots.empty?
        end
      end

      def focused?(slot)
        focus.focused?(slot)
      end

      private

      def focus_ring_slot?(slot)
        self.class.focus_ring_slots.include?(slot)
      end
    end
  end
end
