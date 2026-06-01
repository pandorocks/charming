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
