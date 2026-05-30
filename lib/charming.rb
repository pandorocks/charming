# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "ui" => "UI",
  "tty_backend" => "TTYBackend"
)
loader.setup

module Charming
  class Error < StandardError; end

  def self.run(application, backend: nil)
    Runtime.new(application, backend: backend).run
  end

  def self.key_of(event)
    event.respond_to?(:key) ? event.key : event
  end
end
