# frozen_string_literal: true

RSpec.describe Charming::UI::Width do
  it "measures Unicode display width" do
    expect(described_class.measure("界")).to eq(2)
  end

  it "ignores ANSI escape sequences" do
    expect(described_class.measure("\e[31mHi\e[0m")).to eq(2)
  end

  it "ignores OSC 8 hyperlink sequences (ST-terminated)" do
    linked = "\e]8;;https://example.com\e\\Docs\e]8;;\e\\"
    expect(described_class.measure(linked)).to eq(4)
    expect(described_class.strip_ansi(linked)).to eq("Docs")
  end

  it "ignores BEL-terminated OSC sequences" do
    expect(described_class.strip_ansi("a\e]0;window title\ab")).to eq("ab")
  end

  it "ignores non-SGR CSI sequences" do
    expect(described_class.strip_ansi("a\e[2Jb\e[1;1Hc")).to eq("abc")
  end
end
