# frozen_string_literal: true

RSpec.describe Charming::View do
  it "exposes keyword assigns as reader methods" do
    view = Class.new(described_class) do
      def render
        "Hello #{name}"
      end
    end

    expect(view.new(name: "Ruby").render).to eq("Hello Ruby")
  end

  it "does not override existing private helper methods with assigns" do
    view = Class.new(described_class) do
      def render
        style.foreground(:cyan).render("Hello")
      end
    end

    expect(view.new(style: "ignored").render).to eq("\e[36mHello\e[0m")
  end

  it "renders text with optional styles" do
    view = Class.new(described_class) do
      def render
        text "Hello", style: style.bold
      end
    end

    expect(view.new.render).to eq("\e[1mHello\e[0m")
  end

  it "renders boxes from explicit content" do
    view = Class.new(described_class) do
      def render
        box "Hi", style: style.border(:normal)
      end
    end

    expect(view.new.render).to eq("+--+\n|Hi|\n+--+")
  end

  it "captures text helper calls inside boxes" do
    view = Class.new(described_class) do
      def render
        box(style: style.border(:normal)) do
          text "A"
          text "B"
        end
      end
    end

    expect(view.new.render).to eq("+-+\n|A|\n|B|\n+-+")
  end

  it "composes rows and columns" do
    view = Class.new(described_class) do
      def render
        column(row("A", "B", gap: 1), "C", gap: 1)
      end
    end

    expect(view.new.render).to eq("A B\n\nC")
  end
end
