# frozen_string_literal: true

module Charming
  module Events
    # FocusEvent reports the terminal window gaining or losing focus (focus reporting
    # mode `\e[?1004h`, markers `\e[I` / `\e[O`). Controllers opt in by defining a
    # `focus_changed` action; apps can use it to pause timers or dim the UI.
    FocusEvent = Data.define(:focused) do
      def focused? = focused
    end
  end
end
