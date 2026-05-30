# frozen_string_literal: true

require "stringio"
require "tmpdir"
require "charming/cli"

RSpec.describe Charming::CLI do
  it "generates a runnable gem-style app" do
    Dir.mktmpdir do |dir|
      output = StringIO.new

      status = described_class.new(out: output, pwd: dir).call(%w[new weather_tui])

      app_root = File.join(dir, "weather_tui")
      expect(status).to eq(0)
      expect(output.string).to include("create exe/weather_tui")
      expect(File.executable?(File.join(app_root, "exe/weather_tui"))).to be(true)
      expect(File).to exist(File.join(app_root, "weather_tui.gemspec"))
      expect(File.read(File.join(app_root, "weather_tui.gemspec"))).to include(
        'spec.required_ruby_version = ">= 4.0.0"'
      )
      expect(File.read(File.join(app_root, "weather_tui.gemspec"))).to include(
        'spec.metadata["rubygems_mfa_required"] = "true"'
      )
      root_file = File.read(File.join(app_root, "lib/weather_tui.rb"))
      expect(root_file).to include("loader = Zeitwerk::Loader.new")
      expect(root_file).to include('loader.inflector.inflect("version" => "VERSION")')
      expect(root_file).to include('loader.push_dir(File.expand_path("../app/models", __dir__), namespace: WeatherTui)')
      expect(root_file).not_to include("Dir[File.expand_path")
      expect(File).to exist(File.join(app_root, "config/routes.rb"))
      expect(File).not_to exist(File.join(app_root, "config/themes/default.yml"))
      expect(File).to exist(File.join(app_root, "app/models/application_model.rb"))
      expect(File).to exist(File.join(app_root, "app/models/home_model.rb"))
      expect(File).to exist(File.join(app_root, "app/controllers/application_controller.rb"))
      expect(File).to exist(File.join(app_root, "app/controllers/home_controller.rb"))
      expect(File).to exist(File.join(app_root, "app/views/layouts/application.rb"))
      expect(File.read(File.join(app_root, "spec/models/home_model_spec.rb"))).to include('describe "#title"')
      expect(File.read(File.join(app_root, "spec/controllers/home_controller_spec.rb"))).to include('describe "#show"')
      expect(File.read(File.join(app_root, "spec/views/home_view_spec.rb"))).to include('describe "#render"')
      expect(File.read(File.join(app_root, "spec/views/home_view_spec.rb"))).to include(
        'expect(view.render).to include("WeatherTui")'
      )
      expect(File.read(File.join(app_root, "spec/models/home_model_spec.rb"))).to include('require "weather_tui"')
      expect(File.read(File.join(app_root, "spec/controllers/home_controller_spec.rb"))).to include('require "weather_tui"')
      expect(File.read(File.join(app_root, "spec/views/home_view_spec.rb"))).to include('require "weather_tui"')
      expect(File).not_to exist(File.join(app_root, "app/components/command_palette_modal_component.rb"))
      expect(File).not_to exist(File.join(app_root, "app/controllers/weather_tui/home_controller.rb"))
      expect(File.read(File.join(app_root, "app/controllers/application_controller.rb"))).to include(
        "layout Layouts::Application"
      )
      expect(File.read(File.join(app_root, "app/controllers/application_controller.rb"))).to include(
        "focus_ring :sidebar, :content"
      )
      expect(File.read(File.join(app_root, "app/controllers/application_controller.rb"))).not_to include(
        'key "tab", :focus_sidebar'
      )
      expect(File.read(File.join(app_root, "app/controllers/home_controller.rb"))).to include(
        "class HomeController < ApplicationController"
      )
      expect(File.read(File.join(app_root, "app/views/layouts/application.rb"))).to include(
        "class Application < Charming::View"
      )
      expect(File.read(File.join(app_root, "app/views/layouts/application.rb"))).to include(
        "def sidebar"
      )
      expect(File.read(File.join(app_root, "app/views/layouts/application.rb"))).to include(
        "def content_focused?"
      )
      expect(File.read(File.join(app_root, "app/views/layouts/application.rb"))).to include(
        "base = content_focused? ? theme.primary : style"
      )
      expect(File.read(File.join(app_root, "lib/weather_tui/application.rb"))).to include(
        "Charming::UI::Theme.built_in_names.each do |theme_name|"
      )
      expect(File.read(File.join(app_root, "app/controllers/application_controller.rb"))).to include(
        'command "Theme", :open_theme_palette'
      )

      require File.join(app_root, "lib/weather_tui")
      route = WeatherTui::Application.routes.resolve("/")
      expect(route.controller_class).to eq(WeatherTui::HomeController)
      expect(route.action).to eq(:show)
      expect(WeatherTui::HomeModel.new.title).to eq("WeatherTui")

      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [
          Charming::KeyEvent.new(key: :p, char: "p"),
          Charming::KeyEvent.new(key: :escape),
          Charming::KeyEvent.new(key: :q, char: "q")
        ],
        width: 60,
        height: 12
      )
      Charming::Runtime.new(WeatherTui::Application.new, backend: backend).run
      expect(backend.frames.first).to include("p commands")
      expect(backend.frames.first).to include("q quit")
      expect(backend.frames.join("\n")).to include("Command palette")
      expect(backend.frames.first.lines.count).to eq(12)

      theme_backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [
          Charming::KeyEvent.new(key: :p, char: "p"),
          Charming::KeyEvent.new(key: "t", char: "t"),
          Charming::KeyEvent.new(key: :enter, char: "\n"),
          Charming::KeyEvent.new(key: "t", char: "t"),
          Charming::KeyEvent.new(key: "o", char: "o"),
          Charming::KeyEvent.new(key: "k", char: "k"),
          Charming::KeyEvent.new(key: "y", char: "y"),
          Charming::KeyEvent.new(key: "o", char: "o"),
          Charming::KeyEvent.new(key: :enter, char: "\n"),
          Charming::KeyEvent.new(key: :q, char: "q")
        ],
        width: 60,
        height: 12
      )
      Charming::Runtime.new(WeatherTui::Application.new, backend: theme_backend).run
      expect(theme_backend.frames.join("\n")).to include("Search themes")
      expect(theme_backend.frames.last).to include("\e[38;2;122;162;247m")
    end
  end

  it "generates app files in non-namespaced app folders" do
    Dir.mktmpdir do |dir|
      described_class.new(out: StringIO.new, pwd: dir).call(%w[new weather_tui])
      app_root = File.join(dir, "weather_tui")

      output = StringIO.new
      status = described_class.new(out: output, pwd: app_root).call(%w[g controller forecast index])
      described_class.new(out: output, pwd: app_root).call(%w[g view forecast])
      described_class.new(out: output, pwd: app_root).call(%w[g component forecast_card])

      expect(status).to eq(0)
      expect(output.string).to include("create app/controllers/forecast_controller.rb")
      expect(File).to exist(File.join(app_root, "app/views/forecast_view.rb"))
      expect(File).to exist(File.join(app_root, "app/components/forecast_card_component.rb"))
      expect(File.read(File.join(app_root, "app/controllers/forecast_controller.rb"))).to include(
        "class ForecastController < ApplicationController"
      )
      expect(File.read(File.join(app_root, "app/controllers/forecast_controller.rb"))).to include(
        "render ForecastView.new("
      )
      expect(File.read(File.join(app_root, "app/views/forecast_view.rb"))).to include(
        '"Forecast"'
      )
    end
  end

  it "opens the inherited command palette on generated secondary screens" do
    Dir.mktmpdir do |dir|
      output = StringIO.new
      described_class.new(out: output, pwd: dir).call(%w[new nav_tui])
      app_root = File.join(dir, "nav_tui")
      described_class.new(out: output, pwd: app_root).call(%w[g controller settings show])
      described_class.new(out: output, pwd: app_root).call(%w[g view settings])
      File.write(
        File.join(app_root, "config/routes.rb"),
        "# frozen_string_literal: true\n\nNavTui::Application.routes do\n  root \"settings#show\"\nend\n"
      )

      require File.join(app_root, "lib/nav_tui")
      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [
          Charming::KeyEvent.new(key: :p, char: "p"),
          Charming::KeyEvent.new(key: :escape),
          Charming::KeyEvent.new(key: :q, char: "q")
        ]
      )

      Charming::Runtime.new(NavTui::Application.new, backend: backend).run

      expect(backend.frames.join("\n")).to include("Command palette")
      expect(backend.frames.join("\n")).to include("Home")
    end
  end

  it "generates a routed screen reachable from the command palette" do
    Dir.mktmpdir do |dir|
      output = StringIO.new
      described_class.new(out: output, pwd: dir).call(%w[new screen_tui])
      app_root = File.join(dir, "screen_tui")

      status = described_class.new(out: output, pwd: app_root).call(%w[g screen settings])

      expect(status).to eq(0)
      expect(output.string).to include("create app/models/settings_model.rb")
      expect(output.string).to include("create app/controllers/settings_controller.rb")
      expect(output.string).to include("create app/views/settings_view.rb")
      expect(output.string).to include("insert route config/routes.rb")
      expect(output.string).to include("insert command app/controllers/application_controller.rb")
      expect(File).to exist(File.join(app_root, "spec/models/settings_model_spec.rb"))
      expect(File).to exist(File.join(app_root, "spec/controllers/settings_controller_spec.rb"))
      expect(File).to exist(File.join(app_root, "spec/views/settings_view_spec.rb"))
      expect(File.read(File.join(app_root, "spec/models/settings_model_spec.rb"))).to include(
        'describe "#title"'
      )
      expect(File.read(File.join(app_root, "spec/controllers/settings_controller_spec.rb"))).to include(
        'describe "#show"'
      )
      expect(File.read(File.join(app_root, "spec/views/settings_view_spec.rb"))).to include(
        'describe "#render"'
      )
      expect(File.read(File.join(app_root, "spec/models/settings_model_spec.rb"))).to include(
        'require "screen_tui"'
      )
      expect(File.read(File.join(app_root, "spec/controllers/settings_controller_spec.rb"))).to include(
        'require "screen_tui"'
      )
      expect(File.read(File.join(app_root, "spec/views/settings_view_spec.rb"))).to include(
        'require "screen_tui"'
      )
      expect(File.read(File.join(app_root, "config/routes.rb"))).to include(
        'screen "/settings", to: "settings#show"'
      )
      expect(File.read(File.join(app_root, "app/controllers/application_controller.rb"))).to include(
        'command "Settings" do'
      )

      require File.join(app_root, "lib/screen_tui")
      expect(ScreenTui::Application.routes.resolve("/settings").controller_class).to eq(
        ScreenTui::SettingsController
      )

      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [
          Charming::KeyEvent.new(key: :p, char: "p"),
          Charming::KeyEvent.new(key: "s", char: "s"),
          Charming::KeyEvent.new(key: "e", char: "e"),
          Charming::KeyEvent.new(key: "t", char: "t"),
          Charming::KeyEvent.new(key: "t", char: "t"),
          Charming::KeyEvent.new(key: "i", char: "i"),
          Charming::KeyEvent.new(key: "n", char: "n"),
          Charming::KeyEvent.new(key: "g", char: "g"),
          Charming::KeyEvent.new(key: "s", char: "s"),
          Charming::KeyEvent.new(key: :enter, char: "\n"),
          Charming::KeyEvent.new(key: :p, char: "p"),
          Charming::KeyEvent.new(key: :enter, char: "\n"),
          Charming::KeyEvent.new(key: :q, char: "q")
        ]
      )

      Charming::Runtime.new(ScreenTui::Application.new, backend: backend).run

      expect(backend.frames.join("\n")).to include("Settings")
      expect(backend.frames.last).to include("ScreenTui")
    end
  end

  it "does not duplicate screen route or command when forced" do
    Dir.mktmpdir do |dir|
      output = StringIO.new
      described_class.new(out: output, pwd: dir).call(%w[new duplicate_tui])
      app_root = File.join(dir, "duplicate_tui")

      described_class.new(out: output, pwd: app_root).call(%w[g screen settings])
      described_class.new(out: output, pwd: app_root).call(%w[g screen settings --force])

      routes = File.read(File.join(app_root, "config/routes.rb"))
      application_controller = File.read(File.join(app_root, "app/controllers/application_controller.rb"))
      expect(routes.scan('screen "/settings", to: "settings#show"').size).to eq(1)
      expect(application_controller.scan('command "Settings" do').size).to eq(1)
    end
  end

  it "rejects the removed g scaffold subcommand" do
    Dir.mktmpdir do |dir|
      described_class.new(out: StringIO.new, pwd: dir).call(%w[new legacy_tui])
      app_root = File.join(dir, "legacy_tui")

      error = StringIO.new
      status = described_class.new(out: StringIO.new, err: error, pwd: app_root).call(%w[g scaffold settings])

      expect(status).to eq(1)
      expect(error.string).to include("Unknown generator: scaffold")
    end
  end

  it "refuses to overwrite existing files" do
    Dir.mktmpdir do |dir|
      described_class.new(out: StringIO.new, pwd: dir).call(%w[new weather_tui])

      error = StringIO.new
      status = described_class.new(err: error, pwd: dir).call(%w[new weather_tui])

      expect(status).to eq(1)
      expect(error.string).to include("File already exists: Gemfile")
    end
  end
end
