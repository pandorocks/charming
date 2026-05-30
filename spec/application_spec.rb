# frozen_string_literal: true

require "tmpdir"

RSpec.describe Charming::Application do
  it "registers multiple themes and switches the active theme" do
    application_class = Class.new(described_class) do
      theme :opencode, built_in: "opencode"
      theme :catppuccin, built_in: "catppuccin"
      default_theme :opencode
    end

    application = application_class.new

    expect(application.theme.primary.render("Hi")).to eq("\e[38;2;250;178;131mHi\e[0m")

    application.use_theme(:catppuccin)

    expect(application.theme.primary.render("Hi")).to eq("\e[38;2;180;190;254mHi\e[0m")
  end

  it "resolves opencode JSON theme paths relative to the application root" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "custom.json"), custom_theme_json(primary: "#112233"))

      application_class = Class.new(described_class) do
        root dir
        theme :default, from: "custom.json"
        default_theme :default
      end

      expect(application_class.new.theme.primary.render("Hi")).to eq("\e[38;2;17;34;51mHi\e[0m")
    end
  end

  it "passes the active theme into layouts" do
    layout_class = Class.new(Charming::View) do
      def render
        theme.primary.render(yield_content)
      end
    end

    controller_class = Class.new(Charming::Controller) do
      layout layout_class

      def show
        render "Hi"
      end
    end

    application_class = Class.new(described_class) do
      theme :default, built_in: "tokyonight"
      default_theme :default
    end

    response = controller_class.new(application: application_class.new).dispatch(:show)

    expect(response.body).to eq("\e[38;2;122;162;247mHi\e[0m")
  end

  def custom_theme_json(primary:)
    <<~JSON
      {
        "name": "Custom",
        "id": "custom",
        "light": {
          "palette": {
            "neutral": "#ffffff",
            "ink": "#111111",
            "primary": "#{primary}",
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
            "primary": "#{primary}",
            "success": "#00aa00",
            "warning": "#aaaa00",
            "error": "#aa0000",
            "info": "#0000aa"
          }
        }
      }
    JSON
  end
end
