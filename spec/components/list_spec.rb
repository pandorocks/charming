# frozen_string_literal: true

RSpec.describe Charming::Components::List do
  def key(name)
    Charming::KeyEvent.new(key: name)
  end

  it "selects the first item by default" do
    list = described_class.new(items: %w[Open Quit])

    expect(list.selected_index).to eq(0)
    expect(list.selected_item).to eq("Open")
  end

  it "moves selection down and up" do
    list = described_class.new(items: %w[Open Run Quit])

    expect(list.handle_key(key(:down))).to eq(:handled)
    list.handle_key(key(:down))
    list.handle_key(key(:up))

    expect(list.selected_index).to eq(1)
    expect(list.selected_item).to eq("Run")
  end

  it "clamps movement at list boundaries" do
    list = described_class.new(items: %w[Open Quit])

    list.handle_key(key(:up))
    expect(list.selected_index).to eq(0)

    list.handle_key(key(:down))
    list.handle_key(key(:down))
    expect(list.selected_index).to eq(1)
  end

  it "moves selection home and end" do
    list = described_class.new(items: %w[Open Run Quit], selected_index: 1)

    list.handle_key(key(:end))
    expect(list.selected_item).to eq("Quit")

    list.handle_key(key(:home))
    expect(list.selected_item).to eq("Open")
  end

  it "returns the selected item on enter" do
    list = described_class.new(items: %w[Open Quit], selected_index: 1)

    expect(list.handle_key(key(:enter))).to eq([:selected, "Quit"])
  end

  it "ignores unsupported keys" do
    list = described_class.new(items: %w[Open Quit])

    expect(list.handle_key(key(:left))).to be_nil
  end

  it "renders the selected item highlighted" do
    list = described_class.new(items: %w[Open Quit])

    expect(list.render).to eq("\e[7m> Open\e[0m\n  Quit")
  end

  it "supports custom item labels" do
    command = Struct.new(:name)
    list = described_class.new(items: [command.new("Open File")], label: :name.to_proc)

    expect(list.render).to eq("\e[7m> Open File\e[0m")
  end

  it "renders a viewport around the selected item" do
    list = described_class.new(items: %w[One Two Three Four], selected_index: 2, height: 2)

    expect(list.render).to eq("  Two\n\e[7m> Three\e[0m")
  end
end
