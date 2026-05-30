# frozen_string_literal: true

require "tmpdir"

RSpec.describe Charming::UI::Theme do
  it "turns color shorthand into foreground styles" do
    theme = described_class.new(primary: "#112233")

    expect(theme.primary.render("Hi")).to eq("\e[38;2;17;34;51mHi\e[0m")
  end

  it "turns style mappings into composed styles" do
    theme = described_class.new(
      selection: {
        foreground: :black,
        background: "#ffffff",
        reverse: true
      }
    )

    expect(theme.selection.render("Hi")).to eq("\e[7;30;48;2;255;255;255mHi\e[0m")
  end

  it "loads opencode JSON theme files" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "theme.json")
      File.write(path, opencode_theme_json)

      theme = described_class.load_file(path)

      expect(theme.primary.render("Hi")).to eq("\e[38;2;17;34;51mHi\e[0m")
      expect(theme.muted.render("Hi")).to eq("\e[38;2;102;119;136mHi\e[0m")
    end
  end

  it "loads bundled opencode themes" do
    theme = described_class.load_builtin("tokyonight")

    expect(described_class.built_in_names).to include("tokyonight")
    expect(theme.primary.render("Hi")).to eq("\e[38;2;122;162;247mHi\e[0m")
  end

  def opencode_theme_json
    <<~JSON
      {
        "name": "Custom",
        "id": "custom",
        "light": {
          "palette": {
            "neutral": "#ffffff",
            "ink": "#111111",
            "primary": "#112233",
            "success": "#00aa00",
            "warning": "#aaaa00",
            "error": "#aa0000",
            "info": "#0000aa"
          }
        },
        "dark": {
          "palette": {
            "neutral": "#000000",
            "ink": "#eeeeee",
            "primary": "#112233",
            "success": "#00aa00",
            "warning": "#aaaa00",
            "error": "#aa0000",
            "info": "#0000aa"
          },
          "overrides": {
            "text-weak": "#667788"
          }
        }
      }
    JSON
  end
end
