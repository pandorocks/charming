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
    render <<~VIEW
      Charming counter

      Count: #{session[:count]}

      Press up/down to change the count.
      Press q to quit.
    VIEW
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new)
