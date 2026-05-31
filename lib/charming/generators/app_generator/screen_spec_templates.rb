# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module ScreenSpecTemplates
        def spec_model
          %(# frozen_string_literal: true

require "#{app_name.snake_name}"

RSpec.describe #{app_name.class_name}::#{name.class_name}Model do
  describe "#title" do
    it "has the correct default string value" do
      instance = described_class.new
      expect(instance.title).to eq("#{name.class_name}")
    end

    it "accepts overridden title values" do
      instance = described_class.new(title: "Alternative")
      expect(instance.title).to eq("Alternative")
    end
  end
end
)
        end

        def spec_controller
          %(# frozen_string_literal: true

require "#{app_name.snake_name}"

RSpec.describe #{app_name.class_name}::#{name.controller_class_name} do
  let(:application) { #{app_name.class_name}::Application.new }

  subject(:controller) { described_class.new(application: application) }

  describe "#show" do
    it "renders the view with the model" do
      response = controller.dispatch(:show)

      expect(response).to respond_to(:body)
    end
  end
end
)
        end

        def spec_view
          %(# frozen_string_literal: true

require "#{app_name.snake_name}"

RSpec.describe #{app_name.class_name}::#{name.view_class_name} do
  describe "#render" do
    it "renders the model title" do
      view = described_class.new(
        #{name.snake_name}: double(title: "#{name.class_name}")
       )

      expect(view.render).to eq("#{name.class_name}")
    end
  end
end
)
        end
      end
    end
  end
end
