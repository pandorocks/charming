# frozen_string_literal: true

Journal::Application.routes do
  root "entries#show", title: "Entries"
  screen "/compose", to: "compose#show", title: "Compose"
  screen "/stats", to: "stats#show", title: "Stats"
  screen "/entries/:id", to: "reader#show", title: "Entry"
  screen "/entries/:id/edit", to: "compose#edit", title: "Edit"
end
