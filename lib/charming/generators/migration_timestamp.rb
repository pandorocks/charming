# frozen_string_literal: true

module Charming
  module Generators
    # MigrationTimestamp produces ActiveRecord-format migration version numbers
    # (YYYYMMDDHHMMSS) that are guaranteed unique within a `db/migrate` directory:
    # when generators run within the same second, the version is bumped one second
    # past the highest existing migration version.
    module MigrationTimestamp
      module_function

      # Returns the next available version string for *migrate_dir*.
      def next(migrate_dir)
        now = Time.now.utc.strftime("%Y%m%d%H%M%S")
        highest = highest_existing(migrate_dir)
        return now unless highest && highest >= now

        (highest.to_i + 1).to_s
      end

      # The highest version prefix among existing migration files, or nil.
      def highest_existing(migrate_dir)
        Dir.glob(File.join(migrate_dir, "*.rb"))
          .filter_map { |path| File.basename(path)[/\A\d{14}/] }
          .max
      end
    end
  end
end
