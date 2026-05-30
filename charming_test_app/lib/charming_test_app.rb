# frozen_string_literal: true

require "charming"
require "zeitwerk"

module CharmingTestApp
end

loader = Zeitwerk::Loader.new
loader.tag = "charming_test_app"
loader.inflector.inflect("version" => "VERSION")
loader.push_dir(File.expand_path("charming_test_app", __dir__), namespace: CharmingTestApp)
loader.push_dir(File.expand_path("../app/models", __dir__), namespace: CharmingTestApp)
loader.push_dir(File.expand_path("../app/components", __dir__), namespace: CharmingTestApp)
loader.push_dir(File.expand_path("../app/views", __dir__), namespace: CharmingTestApp)
loader.push_dir(File.expand_path("../app/controllers", __dir__), namespace: CharmingTestApp)
loader.setup

require_relative "../config/routes"
