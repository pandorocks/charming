# frozen_string_literal: true

require "charming"

require_relative "demo_app/version"
require_relative "demo_app/application"

Dir[File.expand_path("../app/models/**/*.rb", __dir__)].sort.each do |file|
  require file
end
Dir[File.expand_path("../app/components/**/*.rb", __dir__)].sort.each do |file|
  require file
end
Dir[File.expand_path("../app/views/**/*.rb", __dir__)].sort.each do |file|
  require file
end
Dir[File.expand_path("../app/controllers/**/*.rb", __dir__)].sort.each do |file|
  require file
end

require_relative "../config/routes"
