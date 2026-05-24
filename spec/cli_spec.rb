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
      expect(File).to exist(File.join(app_root, "config/routes.rb"))
      expect(File).to exist(File.join(app_root, "app/models/weather_tui/application_model.rb"))
      expect(File).to exist(File.join(app_root, "app/models/weather_tui/home_model.rb"))
      expect(File).to exist(File.join(app_root, "app/controllers/weather_tui/home_controller.rb"))
      expect(File).not_to exist(File.join(app_root, "app/components/weather_tui/command_palette_modal_component.rb"))

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
        ]
      )
      Charming::Runtime.new(WeatherTui::Application.new, backend: backend).run
      expect(backend.frames.join("\n")).to include("Command palette")
    end
  end

  it "generates namespaced app files in an existing app" do
    Dir.mktmpdir do |dir|
      described_class.new(out: StringIO.new, pwd: dir).call(%w[new weather_tui])
      app_root = File.join(dir, "weather_tui")

      output = StringIO.new
      status = described_class.new(out: output, pwd: app_root).call(%w[g controller forecast index])
      described_class.new(out: output, pwd: app_root).call(%w[g view forecast])
      described_class.new(out: output, pwd: app_root).call(%w[g component forecast_card])

      expect(status).to eq(0)
      expect(output.string).to include("create app/controllers/weather_tui/forecast_controller.rb")
      expect(File).to exist(File.join(app_root, "app/views/weather_tui/forecast_view.rb"))
      expect(File).to exist(File.join(app_root, "app/components/weather_tui/forecast_card_component.rb"))
      expect(File.read(File.join(app_root, "app/controllers/weather_tui/forecast_controller.rb"))).to include(
        "class ForecastController < Charming::Controller"
      )
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
