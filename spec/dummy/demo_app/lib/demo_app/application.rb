# frozen_string_literal: true

module DemoApp
  class Application < Charming::Application
    Charming::UI::Theme.built_in_names.each do |theme_name|
      theme theme_name.to_sym, built_in: theme_name
    end

    default_theme :phosphor
  end
end
