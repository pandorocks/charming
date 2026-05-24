# frozen_string_literal: true

require "bundler/setup"
require "charming"

class CounterController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "q", :quit

  def show
    session[:count] ||= 0
    render_counter
  end

  def increment
    session[:count] += 1
    render_counter
  end

  def decrement
    session[:count] -= 1
    render_counter
  end

  private

  def render_counter
    render CounterView.new(count: session[:count])
  end
end

class CounterView < Charming::View
  def render
    render_component CounterCardComponent.new(count: count)
  end
end

class CounterCardComponent < Charming::Component
  def render
    box(column(title, count_line, help, gap: 1), style: card_style)
  end

  private

  def card_style
    style.foreground(:bright_cyan).border(:rounded).padding(1, 3).width(44)
  end

  def title
    text "Charming counter", style: style.bold.align(:center).width(44)
  end

  def count_line
    text "Count: #{count}", style: style.foreground(:bright_white).bold
  end

  def help
    text "Press up/down to change the count.\nPress q to quit.", style: style.foreground(:bright_black)
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new)
