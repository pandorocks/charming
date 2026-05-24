# frozen_string_literal: true

RSpec.describe Charming::Components::CommandPalette do
  def key(name, char: nil)
    Charming::KeyEvent.new(key: name, char: char)
  end

  def command(label, value = label.downcase.tr(" ", "_"))
    described_class::Command.new(label: label, value: value)
  end

  it "renders the search input and command list" do
    palette = described_class.new(commands: [command("Open File"), command("Quit")])

    expect(palette.render).to eq("|Search commands\n\e[7m> Open File\e[0m\n  Quit")
  end

  it "filters commands as the user types" do
    palette = described_class.new(commands: [command("Open File"), command("Quit")])

    expect(palette.handle_key(key("q", char: "q"))).to eq(:handled)

    expect(palette.render).to eq("q|\n\e[7m> Quit\e[0m")
    expect(palette.selected_command.label).to eq("Quit")
  end

  it "moves the selected command down and up" do
    palette = described_class.new(commands: [command("Open"), command("Run"), command("Quit")])

    expect(palette.handle_key(key(:down))).to eq(:handled)
    palette.handle_key(key(:down))
    palette.handle_key(key(:up))

    expect(palette.selected_command.label).to eq("Run")
  end

  it "returns the selected command on enter" do
    quit = command("Quit")
    palette = described_class.new(commands: [command("Open"), quit])

    palette.handle_key(key(:down))

    expect(palette.handle_key(key(:enter))).to eq([:selected, quit])
  end

  it "returns cancelled on escape" do
    palette = described_class.new(commands: [command("Open")])

    expect(palette.handle_key(key(:escape))).to eq(:cancelled)
  end

  it "renders an empty state when no commands match" do
    palette = described_class.new(commands: [command("Open")])

    palette.handle_key(key("z", char: "z"))

    expect(palette.render).to eq("z|\nNo commands found")
    expect(palette.selected_command).to be_nil
  end
end
