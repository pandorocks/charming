# frozen_string_literal: true

RSpec.describe Charming::Presentation::Component do
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

  # Pins down Component as a distinct class even before it grows behavior
  # of its own. Catches a revert to `Component = Charming::Presentation::View` (an alias),
  # which would still pass every other spec but would silently break `is_a?`
  # checks and any future Component-specific behavior.
  describe "identity" do
    it "is a distinct class object, not an alias for View" do
      expect(described_class).not_to equal(Charming::Presentation::View)
    end

    it "is named Charming::Presentation::Component" do
      expect(described_class.name).to eq("Charming::Presentation::Component")
    end

    it "inherits from Charming::Presentation::View" do
      expect(described_class.ancestors).to include(Charming::Presentation::View)
      expect(described_class.superclass).to eq(Charming::Presentation::View)
    end

    it "produces instances that are also View instances" do
      expect(described_class.new).to be_a(Charming::Presentation::View)
    end
  end
end
