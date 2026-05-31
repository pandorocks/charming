# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "ui" => "UI",
  "erb_handler" => "ErbHandler",
  "tty_backend" => "TTYBackend"
)
loader.setup

module Charming
  class Error < StandardError; end

  def self.run(application, backend: nil)
    Runtime.new(application, backend: backend).run
  end

  def self.key_of(event)
    key = event.respond_to?(:key) ? event.key : event
    key.to_sym
  end
end

Charming::Presentation::Templates.register ".tui.erb", Charming::Presentation::Templates::ErbHandler
Charming::Presentation::Templates.register ".txt.erb", Charming::Presentation::Templates::ErbHandler
