# frozen_string_literal: true

DemoApp::Application.routes do
  root "home#show"
  screen "/tables", to: "tables#show", title: "Tables"
end
