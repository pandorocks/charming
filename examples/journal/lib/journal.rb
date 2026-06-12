# frozen_string_literal: true

require "charming"
require "zeitwerk"
require_relative "../config/database"

module Journal
end

loader = Zeitwerk::Loader.new
loader.tag = "journal"
loader.inflector.inflect("version" => "VERSION")
loader.push_dir(File.expand_path("journal", __dir__), namespace: Journal)
loader.push_dir(File.expand_path("../app/models", __dir__), namespace: Journal)
loader.push_dir(File.expand_path("../app/state", __dir__), namespace: Journal)
loader.push_dir(File.expand_path("../app/components", __dir__), namespace: Journal)
loader.push_dir(File.expand_path("../app/views", __dir__), namespace: Journal)
loader.push_dir(File.expand_path("../app/controllers", __dir__), namespace: Journal)
loader.setup

require_relative "../config/routes"
