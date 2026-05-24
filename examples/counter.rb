# frozen_string_literal: true

require "bundler/setup"
require "charming"

class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0

  def increment
    self.count += 1
  end

  def decrement
    self.count -= 1
  end

  def reset
    self.count = 0
  end
end

class CounterController < Charming::Controller
  key "up", :increment
  key "down", :decrement
  key "p", :open_command_palette
  key "q", :quit

  command "Increment counter", :increment
  command "Decrement counter", :decrement
  command "Reset counter", :reset
  command "Close palette", :close_command_palette
  command "Quit app", :quit

  def show
    render_counter
  end

  def increment
    counter.increment
    render_counter
  end

  def decrement
    counter.decrement
    render_counter
  end

  def reset
    counter.reset
    render_counter
  end

  private

  def render_counter
    render CounterView.new(counter: counter, palette: command_palette, screen: screen)
  end

  def counter
    model(:counter, CounterModel)
  end
end

class CounterView < Charming::View
  def render
    body = Charming::UI.center(counter_card, width: screen.width, height: screen.height)
    return body unless palette

    Charming::UI.overlay(body, palette_modal)
  end

  private

  def counter_card
    render_component CounterCardComponent.new(counter: counter, dimmed: !!palette)
  end

  def palette_modal
    render_component Charming::Components::Modal.new(
      content: palette,
      title: "Command palette",
      help: "Type to filter. Enter selects. Escape closes.",
      width: 52
    )
  end
end

class CounterCardComponent < Charming::Component
  def render
    box(column(title, count_line, help, gap: 1), style: card_style)
  end

  private

  def card_style
    base = style.foreground(:bright_cyan).border(:rounded).padding(1, 3).width(44)
    dimmed ? base.faint : base
  end

  def title
    text "Charming counter", style: style.bold.align(:center).width(44)
  end

  def count_line
    text "Count: #{counter.count}", style: style.foreground(:bright_white).bold
  end

  def help
    text "Press up/down to change the count.\nPress p for commands, q to quit.",
         style: style.foreground(:bright_black)
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new) if $PROGRAM_NAME == __FILE__
