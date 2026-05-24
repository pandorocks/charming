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
    render "Count: #{session[:count]}"
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

backend = Charming::Internal::Terminal::MemoryBackend.new(
  events: [
    Charming::KeyEvent.new(key: :up),
    Charming::KeyEvent.new(key: :up),
    Charming::KeyEvent.new(key: :down),
    Charming::KeyEvent.new(key: :q)
  ]
)

Charming::Runtime.new(CounterApp.new, backend: backend).run

puts backend.frames
