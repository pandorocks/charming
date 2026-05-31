# frozen_string_literal: true

RSpec.describe Charming::Components::Viewport do
  def key(name)
    Charming::KeyEvent.new(key: name)
  end

  it "renders content unchanged without dimensions" do
    viewport = described_class.new(content: "One\nTwo")

    expect(viewport.render).to eq("One\nTwo")
  end

  it "clips content vertically using an offset and height" do
    viewport = described_class.new(content: "One\nTwo\nThree", offset: 1, height: 2)

    expect(viewport.render).to eq("Two\nThree")
  end

  it "pads missing vertical space when height exceeds content" do
    viewport = described_class.new(content: "One", height: 3)

    expect(viewport.render).to eq("One\n\n")
  end

  it "clips and pads content horizontally" do
    viewport = described_class.new(content: "abcdef", width: 3, column: 2)

    expect(viewport.render).to eq("cde")
  end

  it "wraps long lines when requested" do
    viewport = described_class.new(content: "abcdef", width: 3, wrap: true)

    expect(viewport.render).to eq("abc\ndef")
  end

  it "clips wrapped content vertically after wrapping" do
    viewport = described_class.new(content: "abcdef", width: 3, height: 1, offset: 1, wrap: true)

    expect(viewport.render).to eq("def")
  end

  it "preserves ANSI styling across wrapped slices" do
    viewport = described_class.new(content: "\e[31mabcdef\e[0m", width: 3, wrap: true)

    expect(viewport.render).to eq("\e[31mabc\e[0m\n\e[31mdef\e[0m")
  end

  it "uses Unicode display width when clipping" do
    viewport = described_class.new(content: "a界b", width: 3)

    expect(viewport.render).to eq("a界")
  end

  it "preserves ANSI styling around clipped content" do
    viewport = described_class.new(content: "\e[31mabcdef\e[0m", width: 3)

    expect(viewport.render).to eq("\e[31mabc\e[0m")
  end

  it "renders component content" do
    component = Class.new(Charming::Component) do
      def render = "Component body"
    end

    viewport = described_class.new(content: component.new, width: 9)

    expect(viewport.render).to eq("Component")
  end

  it "scrolls down and up with keys" do
    viewport = described_class.new(content: "One\nTwo\nThree", height: 2)

    expect(viewport.handle_key(key(:down))).to eq(:handled)
    expect(viewport.render).to eq("Two\nThree")

    viewport.handle_key(key(:up))
    expect(viewport.render).to eq("One\nTwo")
  end

  it "scrolls by pages" do
    viewport = described_class.new(content: "One\nTwo\nThree\nFour", height: 2)

    viewport.handle_key(key(:page_down))
    expect(viewport.offset).to eq(2)

    viewport.handle_key(key(:page_up))
    expect(viewport.offset).to eq(0)
  end

  it "scrolls to home and end" do
    viewport = described_class.new(content: "One\nTwo\nThree", width: 3, height: 1)

    viewport.handle_key(key(:end))
    expect(viewport.offset).to eq(2)
    expect(viewport.column).to eq(2)

    viewport.handle_key(key(:home))
    expect(viewport.offset).to eq(0)
    expect(viewport.column).to eq(0)
  end

  it "scrolls horizontally with left and right keys" do
    viewport = described_class.new(content: "abcdef", width: 3)

    viewport.handle_key(key(:right))
    expect(viewport.render).to eq("bcd")

    viewport.handle_key(key(:left))
    expect(viewport.render).to eq("abc")
  end

  it "does not scroll horizontally when wrapping" do
    viewport = described_class.new(content: "abcdef", width: 3, height: 1, wrap: true)

    viewport.handle_key(key(:right))

    expect(viewport.column).to eq(0)
    expect(viewport.render).to eq("abc")
  end

  it "clamps scrolling at content boundaries" do
    viewport = described_class.new(content: "One\nTwo", width: 3, height: 1)

    3.times { viewport.handle_key(key(:down)) }
    3.times { viewport.handle_key(key(:right)) }

    expect(viewport.offset).to eq(1)
    expect(viewport.column).to eq(0)
  end

  it "ignores unsupported keys" do
    viewport = described_class.new(content: "One")

    expect(viewport.handle_key(key(:enter))).to be_nil
  end
end
