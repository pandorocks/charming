# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module DatabaseTemplates
        def database_config
          %(# frozen_string_literal: true

require "active_record"
require "fileutils"

database_path = File.expand_path("../db/development.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(database_path))

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: database_path
)
)
        end

        def application_record
          %(# frozen_string_literal: true

module #{name.class_name}
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
)
        end

        def keep
          ""
        end

        def seeds
          %(# frozen_string_literal: true
)
        end
      end
    end
  end
end
