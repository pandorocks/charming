# frozen_string_literal: true

require "active_record"
require "fileutils"

# The database file is selected by CHARMING_ENV (development, test, production).
environment = ENV["CHARMING_ENV"] || "development"
database_path = File.expand_path("../db/#{environment}.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(database_path))

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: database_path
)
