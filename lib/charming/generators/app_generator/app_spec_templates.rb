# frozen_string_literal: true

module Charming
  module Generators
    class AppGenerator
      module AppSpecTemplates
        def spec_state
          %(# frozen_string_literal: true

require "#{app_name.snake_name}"

RSpec.describe #{app_name.class_name}::HomeState do
  describe "#title" do
    it "has the correct default string value" do
      instance = described_class.new
      expect(instance.title).to eq("#{app_name.class_name}")
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

RSpec.describe #{app_name.class_name}::HomeController do
  let(:application) { #{app_name.class_name}::Application.new }

  subject(:controller) { described_class.new(application: application) }

  describe "#show" do
    it "renders the view with the state" do
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

RSpec.describe #{app_name.class_name}::Home::ShowView do
  describe "#render" do
    it "renders the state title" do
      view = described_class.new(
        home: double(title: "#{app_name.class_name}"),
        theme: #{app_name.class_name}::Application.new.theme
      )

      expect(view.render).to include("#{app_name.class_name}")
    end
  end
end
)
        end
      end
    end
  end
end
