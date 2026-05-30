# frozen_string_literal: true

require_relative "charming/version"
require_relative "charming/application_model"
require_relative "charming/application"
require_relative "charming/controller"
require_relative "charming/events"
require_relative "charming/response"
require_relative "charming/router"
require_relative "charming/screen"
require_relative "charming/runtime"
require_relative "charming/ui"
require_relative "charming/view"
require_relative "charming/component"
require_relative "charming/components/command_palette"
require_relative "charming/components/list"
require_relative "charming/components/modal"
require_relative "charming/components/spinner"
require_relative "charming/components/text_input"
require_relative "charming/components/table"
require_relative "charming/components/viewport"

module Charming
  class Error < StandardError; end

  def self.run(application, backend: nil)
    Runtime.new(application, backend: backend).run
  end
end
