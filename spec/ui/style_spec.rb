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

  it "expands #rgb short hex colors" do
    output = described_class.new.foreground("#a1c").render("Hi")

    expect(output).to eq("\e[38;2;170;17;204mHi\e[0m")
  end

  it "resolves adaptive colors against the terminal background" do
    color = Charming::UI.adaptive(light: :black, dark: :white)

    Charming::UI::Background.assume = :dark
    on_dark = described_class.new.foreground(color).render("Hi")
    Charming::UI::Background.assume = :light
    on_light = described_class.new.foreground(color).render("Hi")

    expect(on_dark).to eq("\e[37mHi\e[0m")
    expect(on_light).to eq("\e[30mHi\e[0m")
  ensure
    Charming::UI::Background.assume = nil
  end

  it "pads content" do
    output = described_class.new.padding(1, 2).render("Hi")

    expect(output).to eq("      \n  Hi  \n      ")
  end

  it "pads individual sides" do
    output = described_class.new.padding_left(2).padding_top(1).render("Hi")

    expect(output).to eq("    \n  Hi")
  end

  it "applies margin as unstyled space outside border and colors" do
    output = described_class.new.foreground(:red).border(:normal).margin(1, 2).render("Hi")

    expect(output).to eq(
      "        \n" \
      "  \e[31m+--+\e[0m  \n" \
      "  \e[31m|Hi|\e[0m  \n" \
      "  \e[31m+--+\e[0m  \n" \
      "        "
    )
  end

  it "applies margin to individual sides" do
    output = described_class.new.margin_left(3).render("Hi")

    expect(output).to eq("   Hi")
  end

  it "vertically centers content within a fixed height" do
    output = described_class.new.width(3).height(3).align_vertical(:middle).render("Hi")

    expect(output).to eq("   \nHi \n   ")
  end

  it "bottom-aligns content within a fixed height" do
    output = described_class.new.width(3).height(3).align_vertical(:bottom).render("Hi")

    expect(output).to eq("   \n   \nHi ")
  end

  it "top-aligns content within a fixed height by default" do
    output = described_class.new.width(3).height(3).render("Hi")

    expect(output).to eq("Hi \n   \n   ")
  end

  it "renders borders" do
    output = described_class.new.border(:rounded).render("Hi")

    expect(output).to eq("╭──╮\n│Hi│\n╰──╯")
  end

  it "renders a square box-drawing border" do
    output = described_class.new.border(:square).render("Hi")

    expect(output).to eq("┌──┐\n│Hi│\n└──┘")
  end

  it "renders a hidden border that preserves the box footprint" do
    output = described_class.new.border(:hidden).render("Hi")

    expect(output).to eq("    \n Hi \n    ")
  end

  it "renders a block border" do
    output = described_class.new.border(:block).render("Hi")

    expect(output).to eq("████\n█Hi█\n████")
  end

  it "accepts a custom Border instance" do
    border = Charming::UI::Border.new(corners: %w[1 2 3 4], edges: %w[= !])
    output = described_class.new.border(border).render("Hi")

    expect(output).to eq("1==2\n!Hi!\n3==4")
  end

  it "colors the border background independently of the box" do
    output = described_class.new.border(:normal, foreground: :red, background: :blue).render("Hi")

    expect(output).to eq("\e[31;44m+--+\e[0m\n\e[31;44m|\e[0mHi\e[31;44m|\e[0m\n\e[31;44m+--+\e[0m")
  end

  it "colors border sides individually" do
    output = described_class.new.border(
      :normal,
      foreground: {top: :red, bottom: :blue, left: :green, right: :yellow}
    ).render("Hi")

    expect(output).to eq("\e[31m+--+\e[0m\n\e[32m|\e[0mHi\e[33m|\e[0m\n\e[34m+--+\e[0m")
  end

  it "aligns content using Unicode display width" do
    output = described_class.new.width(6).align(:center).render("界")

    expect(output).to eq("  界  ")
  end

  it "clips content beyond a fixed width" do
    output = described_class.new.width(3).render("ABCDE")

    expect(output).to eq("ABC")
  end

  it "truncates with an ellipsis in truncate mode" do
    output = described_class.new.width(4).truncate.render("ABCDE")

    expect(output).to eq("ABC…")
  end

  it "word-wraps at a fixed width in wrap mode" do
    output = described_class.new.width(7).wrap.render("Hello wide world")

    expect(output).to eq("Hello  \nwide   \nworld  ")
  end

  it "caps width with max_width without padding shorter lines beyond their block" do
    output = described_class.new.max_width(3).render("ABCDE\nZ")

    expect(output).to eq("ABC\nZ  ")
  end

  it "leaves content narrower than max_width untouched" do
    output = described_class.new.max_width(10).render("Hi")

    expect(output).to eq("Hi")
  end

  it "caps rows with max_height without filling missing rows" do
    output = described_class.new.max_height(2).render("A\nB\nC")

    expect(output).to eq("A\nB")
  end

  it "leaves content shorter than max_height untouched" do
    output = described_class.new.max_height(5).render("A\nB")

    expect(output).to eq("A\nB")
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
