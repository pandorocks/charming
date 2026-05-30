# frozen_string_literal: true

require "charming"
require "zeitwerk"

module DemoApp
end

loader = Zeitwerk::Loader.new
loader.tag = "demo_app"
loader.inflector.inflect("version" => "VERSION")
loader.push_dir(File.expand_path("demo_app", __dir__), namespace: DemoApp)
loader.push_dir(File.expand_path("../app/models", __dir__), namespace: DemoApp)
loader.push_dir(File.expand_path("../app/components", __dir__), namespace: DemoApp)
loader.push_dir(File.expand_path("../app/views", __dir__), namespace: DemoApp)
loader.push_dir(File.expand_path("../app/controllers", __dir__), namespace: DemoApp)
loader.setup

require_relative "../config/routes"
