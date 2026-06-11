# frozen_string_literal: true

module Charming
  module Events
    # PasteEvent carries text pasted via the terminal's bracketed-paste mode
    # (`\e[200~ ... \e[201~`). Without bracketed paste, pasted text arrives as a storm
    # of individual key events; with it, components receive the whole string at once
    # via `handle_paste`.
    PasteEvent = Data.define(:text)
  end
end
