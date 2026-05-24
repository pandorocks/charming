# frozen_string_literal: true

module Charming
  module Generators
    module AppGeneratorTemplates
      module ModelTemplates
        def application_model
          %(# frozen_string_literal: true

module #{name.class_name}
  class ApplicationModel < Charming::ApplicationModel
  end
end
)
        end

        def home_model
          %(# frozen_string_literal: true

module #{name.class_name}
  class HomeModel < ApplicationModel
    attribute :title, :string, default: "#{name.class_name}"
  end
end
)
        end
      end
    end
  end
end
