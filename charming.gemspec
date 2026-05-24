# frozen_string_literal: true

require_relative "lib/charming/version"

Gem::Specification.new do |spec|
  spec.name = "charming"
  spec.version = Charming::VERSION
  spec.authors = ["lbp"]
  spec.email = ["git@lbp.dev"]

  spec.summary = "A Rails-inspired TUI framework for Ruby."
  spec.description = "Charming brings Rails-like application, routing, controller, and rendering " \
                     "conventions to Ruby terminal user interfaces."
  spec.homepage = "https://github.com/lbp/charming"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib,sig}/**/*") + %w[LICENSE.txt README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ["lib"]

  spec.add_dependency "tty-cursor", "~> 0.7"
  spec.add_dependency "tty-reader", "~> 0.9"
  spec.add_dependency "tty-screen", "~> 0.8"
  spec.add_dependency "unicode-display_width", "~> 2.6"
end
