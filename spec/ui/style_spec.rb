# frozen_string_literal: true

RSpec.describe Charming::UI::Style do
  it "applies ANSI foreground color and attributes" do
    output = described_class.new.foreground(:cyan).bold.render("Hello")

    expect(output).to eq("\e[1;36mHello\e[0m")
  end

  it "supports 256-color and truecolor backgrounds" do
    indexed = described_class.new.foreground(45).render("Hi")
    truecolor = described_class.new.background("#112233").render("Hi")

    expect(indexed).to eq("\e[38;5;45mHi\e[0m")
    expect(truecolor).to eq("\e[48;2;17;34;51mHi\e[0m")
  end

  it "pads content" do
    output = described_class.new.padding(1, 2).render("Hi")

    expect(output).to eq("      \n  Hi  \n      ")
  end

  it "renders borders" do
    output = described_class.new.border(:rounded).render("Hi")

    expect(output).to eq("╭──╮\n│Hi│\n╰──╯")
  end

  it "aligns content using Unicode display width" do
    output = described_class.new.width(6).align(:center).render("界")

    expect(output).to eq("  界  ")
  end

  it "combines layout and ANSI styling" do
    output = described_class.new.foreground(:red).padding(0, 1).border(:normal).render("Hi")

    expect(output).to eq("\e[31m+----+\n| Hi |\n+----+\e[0m")
  end
end
