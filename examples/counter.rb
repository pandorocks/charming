# frozen_string_literal: true

require "bundler/setup"
require "charming"

class CounterController < Charming::Controller
  ("a".."z").each { |letter| key letter, :handle_key }
  ("0".."9").each { |number| key number, :handle_key }
  %w[space backspace delete up down home end enter escape].each do |name|
    key name, :handle_key
  end

  def show
    session[:count] ||= 0
    render_counter
  end

  def handle_key
    if palette_open?
      handle_palette_key
    else
      handle_counter_key
    end

    render_counter unless response
  end

  private

  def handle_counter_key
    case event.key.to_sym
    when :up then increment
    when :down then decrement
    when :p then open_palette
    when :q then quit
    end
  end

  def handle_palette_key
    result = palette.handle_key(event)
    close_palette if result == :cancelled
    apply_command(result.last) if selected?(result)
  end

  def increment
    session[:count] += 1
  end

  def decrement
    session[:count] -= 1
  end

  def reset
    session[:count] = 0
  end

  def open_palette
    session[:palette] = build_palette
  end

  def close_palette
    session.delete(:palette)
  end

  def palette_open?
    session.key?(:palette)
  end

  def palette
    session[:palette]
  end

  def build_palette
    Charming::Components::CommandPalette.new(commands: commands, height: 6)
  end

  def commands
    [
      command("Increment counter", :increment),
      command("Decrement counter", :decrement),
      command("Reset counter", :reset),
      command("Close palette", :close_palette),
      command("Quit app", :quit)
    ]
  end

  def command(label, value)
    Charming::Components::CommandPalette::Command.new(label: label, value: value)
  end

  def selected?(result)
    result.is_a?(Array) && result.first == :selected
  end

  def apply_command(command)
    send(command.value)
    close_palette unless command.value == :quit
  end

  def render_counter
    render CounterView.new(count: session[:count], palette: palette)
  end
end

class CounterView < Charming::View
  WIDTH = 80
  HEIGHT = 24

  def render
    screen = Charming::UI.center(counter_card, width: WIDTH, height: HEIGHT)
    return screen unless palette

    Charming::UI.overlay(screen, palette_modal)
  end

  private

  def counter_card
    render_component CounterCardComponent.new(count: count, dimmed: !!palette)
  end

  def palette_modal
    render_component CommandPaletteModalComponent.new(palette: palette)
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
    text "Count: #{count}", style: style.foreground(:bright_white).bold
  end

  def help
    text "Press up/down to change the count.\nPress p for commands, q to quit.",
         style: style.foreground(:bright_black)
  end
end

class CommandPaletteModalComponent < Charming::Component
  def render
    box(column(title, help, render_component(palette), gap: 1), style: modal_style)
  end

  private

  def title
    text "Command palette", style: style.bold.align(:center).width(44)
  end

  def help
    text "Type to filter. Enter selects. Escape closes.", style: style.foreground(:bright_black)
  end

  def modal_style
    style.foreground(:bright_magenta).border(:double).padding(1, 3).width(52)
  end
end

class CounterApp < Charming::Application
  routes do
    root "counter#show"
  end
end

Charming.run(CounterApp.new) if $PROGRAM_NAME == __FILE__
