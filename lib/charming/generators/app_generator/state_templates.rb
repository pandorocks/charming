# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module StateTemplates
        def application_state
          %(# frozen_string_literal: true

module #{name.class_name}
  class ApplicationState < Charming::ApplicationState
  end
end
)
        end

        def home_state
          %(# frozen_string_literal: true

module #{name.class_name}
  class HomeState < ApplicationState
    attribute :title, :string, default: "#{name.class_name}"
  end
end
)
        end
      end
    end
  end
end
