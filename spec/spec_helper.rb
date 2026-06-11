# frozen_string_literal: true

require "charming"

# Pin color output to truecolor so rendered ANSI in specs doesn't depend on the
# host terminal's capabilities.
Charming::UI::ColorSupport.level = :truecolor

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
