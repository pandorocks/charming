# frozen_string_literal: true

require "bundler/setup"
require "charming"

class CounterModel < Charming::ApplicationModel
  attribute :count, :integer, default: 0

  attr_reader :entries

  def initialize(**attributes)
    super
    @entries = ["Count started at 0"]
  end

  def increment
    self.count += 1
    log "Incremented to #{count}"
  end

  def decrement
    self.count -= 1
    log "Decremented to #{count}"
  end

  def reset
    self.count = 0
    log "Reset to 0"
  end

  def log(message)
    entries << message
  end
end

class CounterController < Charming::Controller
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

  def scroll_log_down
    log_viewport.handle_key(:down)
    render_counter
  end

  def scroll_log_up
    log_viewport.handle_key(:up)
    render_counter
  end

  def scroll_log
    log_viewport.handle_key(event)
    render_counter
  end

  private

  def render_counter
    render CounterView.new(counter: counter, log_viewport: log_viewport, palette: command_palette, screen: screen)
  end

  def counter
    model(:counter, CounterModel)
  end

  def log_viewport
    session[:log_viewport] ||= Charming::Components::Viewport.new(
      content: ActivityLogContentComponent.new(counter: counter),
      width: 30,
      height: 4
    )
  end
end

class CounterView < Charming::View
  def render
    body = Charming::UI.center(content, width: screen.width, height: screen.height)
    return body unless palette

    Charming::UI.overlay(body, palette_modal)
  end

  private

  def counter_card
    render_component CounterCardComponent.new(counter: counter, dimmed: !!palette)
  end

  def activity_log
    render_component ActivityLogPanelComponent.new(viewport: log_viewport, dimmed: !!palette)
  end

  def content
    return row(counter_card, activity_log, gap: 2) if screen.width >= 78 || screen.height < 20

    column(counter_card, activity_log, gap: 1)
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
    base = style.foreground(:bright_cyan).border(:rounded).padding(1, 3).width(28)
    dimmed ? base.faint : base
  end

  def title
    text "Charming counter", style: style.bold.align(:center).width(28)
  end

  def count_line
    text "Count: #{counter.count}", style: style.foreground(:bright_white).bold
  end

  def help
    text "up/down changes count\nj/k scrolls log\np commands, q quits",
         style: style.foreground(:bright_black)
  end
end

class ActivityLogPanelComponent < Charming::Component
  def render
    box(column(title, render_component(viewport), help, gap: 1), style: panel_style)
  end

  private

  def title
    text "Activity log", style: style.bold.align(:center).width(30)
  end

  def help
    text "j/k, page up/down, home/end", style: style.foreground(:bright_black)
  end

  def panel_style
    base = style.foreground(:bright_blue).border(:rounded).padding(1, 3).width(30)
    dimmed ? base.faint : base
  end
end

class ActivityLogContentComponent < Charming::Component
  def render
    counter.entries.join("\n")
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new) if $PROGRAM_NAME == __FILE__
