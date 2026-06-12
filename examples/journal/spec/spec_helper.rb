# frozen_string_literal: true

ENV["CHARMING_ENV"] ||= "test"

require "journal"

# Prepare the test database, preferring the dumped schema over replaying migrations.
schema = File.expand_path("../db/schema.rb", __dir__)
if File.exist?(schema)
  load schema
else
  ActiveRecord::MigrationContext.new(File.expand_path("../db/migrate", __dir__)).migrate
end

RSpec.configure do |config|
  # Roll back database writes after each example so tests stay isolated.
  config.around(:each) do |example|
    ActiveRecord::Base.transaction(requires_new: true) do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
