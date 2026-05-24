# frozen_string_literal: true

RSpec.describe Charming::Component do
  it "inherits view assigns" do
    component = Class.new(described_class) do
      def render
        "Hello #{name}"
      end
    end

    expect(component.new(name: "Ruby").render).to eq("Hello Ruby")
  end

  it "inherits view helpers" do
    component = Class.new(described_class) do
      def render
        box "Hi", style: style.border(:normal)
      end
    end

    expect(component.new.render).to eq("+--+\n|Hi|\n+--+")
  end
end
