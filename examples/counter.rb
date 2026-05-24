# frozen_string_literal: true

require "bundler/setup"
require "charming"

class CounterController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "q", :quit

  def show
    session[:count] ||= 0
    render_count
  end

  def increment
    session[:count] += 1
    render_count
  end

  def decrement
    session[:count] -= 1
    render_count
  end

  private

  def render_count
    render Charming::UI.style
                       .foreground(:bright_cyan)
                       .border(:rounded)
                       .padding(1, 3)
                       .width(44)
                       .render(counter_layout)
  end

  def counter_layout
    Charming::UI.join_vertical(
      title,
      count,
      help,
      gap: 1
    )
  end

  def title
    Charming::UI.style.bold.align(:center).width(44).render("Charming counter")
  end

  def count
    Charming::UI.style.foreground(:bright_white).bold.render("Count: #{session[:count]}")
  end

  def help
    Charming::UI.style.foreground(:bright_black).render(
      "Press up/down to change the count.\nPress q to quit."
    )
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new)
