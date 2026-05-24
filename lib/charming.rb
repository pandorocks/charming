# frozen_string_literal: true

require_relative "charming/version"
require_relative "charming/application"
require_relative "charming/controller"
require_relative "charming/events"
require_relative "charming/response"
require_relative "charming/router"
require_relative "charming/runtime"
require_relative "charming/ui"
require_relative "charming/view"

module Charming
  class Error < StandardError; end

  def self.run(application, backend: nil)
    Runtime.new(application, backend: backend).run
  end
end
