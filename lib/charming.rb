# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "cli" => "CLI",
  "ui" => "UI",
  "ansi_codes" => "ANSICodes",
  "ansi_slicer" => "ANSISlicer",
  "border_painter" => "BorderPainter",
  "block_renderers" => "BlockRenderer",
  "inline_renderers" => "InlineRenderer",
  "render_context" => "RenderContext",
  "erb_handler" => "ErbHandler",
  "key_normalizer" => "KeyNormalizer",
  "mouse_parser" => "MouseParser",
  "tty_backend" => "TTYBackend"
)
loader.setup

module Charming
  # Base error class for all Charming-specific exceptions (used by templates, generators, runtime, etc.).
  class Error < StandardError; end

  # Entry point for running a Charming application. Instantiates a Runtime for *application* and starts
  # the event loop. *backend* defaults to TTYBackend; tests pass MemoryBackend directly via `Charming::Runtime.new`.
  def self.run(application, backend: nil)
    Runtime.new(application, backend: backend).run
  end

  # Returns the normalized key symbol for an event-like object — `event.key` when the object responds
  # to it, otherwise `event.to_sym`. Lets components treat raw strings and KeyEvent objects uniformly.
  def self.key_of(event)
    key = event.respond_to?(:key) ? event.key : event
    key.to_sym
  end
end

Charming::Presentation::Templates.register ".tui.erb", Charming::Presentation::Templates::ErbHandler
Charming::Presentation::Templates.register ".txt.erb", Charming::Presentation::Templates::ErbHandler
