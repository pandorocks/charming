# frozen_string_literal: true

require_relative "lib/charming_test_app/version"

Gem::Specification.new do |spec|
  spec.name = "charming_test_app"
  spec.version = CharmingTestApp::VERSION
  spec.summary = "A Charming terminal user interface."
  spec.authors = ["TODO: Your name"]
  spec.email = ["TODO: Your email"]
  spec.files = Dir.glob("{app,config,exe,lib}/**/*") + %w[README.md]
  spec.bindir = "exe"
  spec.executables = ["charming_test_app"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "charming"
end
