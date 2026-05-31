# frozen_string_literal: true

require "tmpdir"

RSpec.describe Charming::UI::Theme do
  it "turns color shorthand into foreground styles" do
    theme = described_class.new(title: "#112233")

    expect(theme.title.render("Hi")).to eq("\e[38;2;17;34;51mHi\e[0m")
  end

  it "turns style mappings into composed styles" do
    theme = described_class.new(
      selected: {
        foreground: :black,
        background: "#ffffff",
        bold: true
      }
    )

    expect(theme.selected.render("Hi")).to eq("\e[1;30;48;2;255;255;255mHi\e[0m")
  end

  it "loads Charming JSON theme files" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "theme.json")
      File.write(path, charming_theme_json)

      theme = described_class.load_file(path)

      expect(theme.title.render("Hi")).to eq("\e[1;38;2;17;34;51mHi\e[0m")
      expect(theme.muted.render("Hi")).to eq("\e[38;2;102;119;136mHi\e[0m")
    end
  end

  it "loads the bundled Phosphor theme" do
    theme = described_class.load_builtin("phosphor")

    expect(described_class.built_in_names).to eq(["phosphor"])
    expect(theme.title.render("Hi")).to eq("\e[1;38;2;255;179;71;48;2;17;26;44mHi\e[0m")
    expect(theme.selected.render("Hi")).to eq("\e[1;38;2;159;232;176;48;2;24;35;61mHi\e[0m")
  end

  def charming_theme_json
    <<~JSON
      {
        "name": "Custom",
        "id": "custom",
        "palette": {
          "title": "#112233",
          "muted": "#667788"
        },
        "styles": {
          "title": {
            "foreground": "title",
            "bold": true
          },
          "muted": {
            "foreground": "muted"
          }
        }
      }
    JSON
  end
end
