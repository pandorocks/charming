# frozen_string_literal: true

module Charming
  module Image
    # Protocol namespaces the terminal-graphics encoders and dispatches to one by name. Each encoder
    # (e.g. {Protocol::Kitty}) exposes the same surface — `transmit(...)` for the out-of-band payload
    # and `placeholder_block(...)` for the in-frame cells — so {Source} stays protocol-agnostic.
    module Protocol
      # Returns the encoder module for *name* (a {Terminal#protocol} symbol), or nil when no encoder
      # applies (e.g. `:none`).
      def self.for(name)
        case name
        when :kitty then Kitty
        end
      end
    end
  end
end
