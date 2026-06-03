# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe Charming::Application do
  it "derives its namespace from the application class name" do
    stub_const("NamespaceSpec", Module.new)
    stub_const("NamespaceSpec::Application", Class.new(described_class))

    expect(NamespaceSpec::Application.namespace).to eq("NamespaceSpec")
  end

  it "provides a null logger by default" do
    application = described_class.new

    expect(application.logger).to be_a(Logger)
    expect { application.logger.info("discarded") }.not_to raise_error
  end

  it "uses a configured class logger" do
    output = StringIO.new
    configured_logger = Logger.new(output)
    application_class = Class.new(described_class) do
      logger configured_logger
    end

    application_class.new.logger.info("configured")

    expect(application_class.logger).to eq(configured_logger)
    expect(output.string).to include("configured")
  end

  it "allows instance logger overrides" do
    output = StringIO.new
    application = described_class.new
    application.logger = Logger.new(output)

    application.logger.info("instance")

    expect(output.string).to include("instance")
  end

  it "registers multiple themes and switches the active theme" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "custom.json"), custom_theme_json(title: "#112233"))

      application_class = Class.new(described_class) do
        root dir
        theme :phosphor, built_in: "phosphor"
        theme :custom, from: "custom.json"
        default_theme :phosphor
      end

      application = application_class.new

      expect(application.theme.title.render("Hi")).to eq("\e[1;38;2;255;179;71;48;2;17;26;44mHi\e[0m")

      application.use_theme(:custom)

      expect(application.theme.title.render("Hi")).to eq("\e[1;38;2;17;34;51mHi\e[0m")
    end
  end

  it "resolves theme paths relative to the application root" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "custom.json"), custom_theme_json(title: "#112233"))

      application_class = Class.new(described_class) do
        root dir
        theme :default, from: "custom.json"
        default_theme :default
      end

      expect(application_class.new.theme.title.render("Hi")).to eq("\e[1;38;2;17;34;51mHi\e[0m")
    end
  end

  it "passes the active theme into layouts" do
    layout_class = Class.new(Charming::View) do
      def render
        theme.title.render(yield_content)
      end
    end

    controller_class = Class.new(Charming::Controller) do
      layout layout_class

      def show
        render "Hi"
      end
    end

    application_class = Class.new(described_class) do
      theme :default, built_in: "phosphor"
      default_theme :default
    end

    response = controller_class.new(application: application_class.new).dispatch(:show)

    expect(response.body).to eq("\e[1;38;2;255;179;71;48;2;17;26;44mHi\e[0m")
  end

  def custom_theme_json(title:)
    <<~JSON
      {
        "name": "Custom",
        "id": "custom",
        "styles": {
          "title": {
            "foreground": "#{title}",
            "bold": true
          }
        },
        "palette": {}
      }
    JSON
  end
end
