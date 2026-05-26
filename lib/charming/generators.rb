# frozen_string_literal: true

require_relative "generators/app_generator"
require_relative "generators/component_generator"
require_relative "generators/controller_generator"
require_relative "generators/scaffold_generator"
require_relative "generators/view_generator"

module Charming
  module Generators
    class Error < StandardError; end
  end
end
