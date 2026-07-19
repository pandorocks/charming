# frozen_string_literal: true

require "charming"
require "active_support/lazy_load_hooks"

# Pin color output to truecolor so rendered ANSI in specs doesn't depend on the
# host terminal's capabilities.
Charming::UI::ColorSupport.level = :truecolor

# The database CLI specs migrate real throwaway apps; keep ActiveRecord's
# "== CreateX: migrating ==" banners (written straight to $stdout) out of the
# spec output. Registered lazily because the suite only loads ActiveRecord on
# the code paths that need it.
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.verbose = false
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
