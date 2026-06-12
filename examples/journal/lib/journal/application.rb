# frozen_string_literal: true

module Journal
  class Application < Charming::Application
    root File.expand_path("../..", __dir__)

    theme :phosphor, built_in: "phosphor"
    theme :mocha, built_in: "catppuccin-mocha"
    theme :nord, built_in: "nord"
    theme :tokyonight, built_in: "tokyonight"

    # A derived theme demonstrating inheritance: phosphor with a louder title.
    theme :phosphor_loud, extends: :phosphor, overrides: {
      title: {foreground: "#FFD75F", bold: true}
    }

    default_theme :phosphor

    # Remember the chosen theme and list position across restarts.
    persist_session to: "tmp/session.json"
  end
end
