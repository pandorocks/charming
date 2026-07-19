# frozen_string_literal: true

DemoApp::Application.routes do
  root "home#show"
  screen "/lg", to: "lg#show", title: "LG Layout"
  screen "/image", to: "image#show", title: "Image"
  screen "/charts", to: "charts#show", title: "Charts"
  screen "/physics", to: "physics#show", title: "Physics"
end
