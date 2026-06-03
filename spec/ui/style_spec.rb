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

  it "clips content beyond a fixed width" do
    output = described_class.new.width(3).render("ABCDE")

    expect(output).to eq("ABC")
  end

  it "pads content to a fixed height" do
    output = described_class.new.width(2).height(3).render("A")

    expect(output).to eq("A \n  \n  ")
  end

  it "clips content beyond a fixed height" do
    output = described_class.new.height(2).render("A\nB\nC")

    expect(output).to eq("A\nB")
  end

  it "combines layout and ANSI styling" do
    output = described_class.new.foreground(:red).padding(0, 1).border(:normal).render("Hi")

    expect(output).to eq("\e[31m+----+\e[0m\n\e[31m| Hi |\e[0m\n\e[31m+----+\e[0m")
  end

  it "keeps outer styling after nested ANSI resets" do
    nested = "\e[1mHi\e[0m"
    output = described_class.new.foreground(:red).border(:normal).render(nested)

    expect(output).to eq("\e[31m+--+\e[0m\n\e[31m|\e[1mHi\e[0m\e[31m|\e[0m\n\e[31m+--+\e[0m")
  end

  it "does not leak inner ANSI styling across newlines into outer borders" do
    # Realistic chain: a multi-line styled text rendered inside a styled box.
    # Pre-fix, the inner gray would carry across newlines and tint the next
    # row's outer border, producing visible gaps in the colored box.
    inner = described_class.new.foreground(:bright_black).render("a\nb")
    output = described_class.new.foreground(:cyan).border(:normal).render(inner)

    expect(output).to eq(
      "\e[36m+-+\e[0m\n" \
      "\e[36m|\e[90ma\e[0m\e[36m|\e[0m\n" \
      "\e[36m|\e[90mb\e[0m\e[36m|\e[0m\n" \
      "\e[36m+-+\e[0m"
    )
  end
end
