# frozen_string_literal: true

module DemoApp
  class HomeController < Charming::Controller
    key "up", :increment
    key "down", :decrement
    key "j", :scroll_log_down
    key "k", :scroll_log_up
    key "page_down", :scroll_log
    key "page_up", :scroll_log
    key "home", :scroll_log
    key "end", :scroll_log
    key "p", :open_command_palette
    key "q", :quit

    command "Increment counter", :increment
    command "Decrement counter", :decrement
    command "Reset counter", :reset
    command "Close palette", :close_command_palette
    command "Quit app", :quit

    timer :spinner, every: 0.1, action: :tick_spinner

    def show
      render_home
    end

    def increment
      home.increment
      render_home
    end

    def decrement
      home.decrement
      render_home
    end

    def reset
      home.reset
      render_home
    end

    def scroll_log_down
      log_viewport.handle_key(:down)
      render_home
    end

    def scroll_log_up
      log_viewport.handle_key(:up)
      render_home
    end

    def scroll_log
      log_viewport.handle_key(event)
      render_home
    end

    def tick_spinner
      spinner.tick
      render_home
    end

    private

    def render_home
      render HomeView.new(
        home: home,
        spinner: spinner,
        log_viewport: log_viewport,
        palette: command_palette,
        screen: screen
      )
    end

    def home
      model(:home, HomeModel)
    end

    def log_viewport
      session[:log_viewport] ||= Charming::Components::Viewport.new(
        content: ActivityLogContentComponent.new(home: home),
        width: 30,
        height: 4
      )
    end

    def spinner
      session[:spinner] ||= Charming::Components::Spinner.new(label: "Ready")
    end
  end
end
