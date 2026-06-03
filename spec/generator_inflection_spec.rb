# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe "generator inflections" do
  it "camelizes generator names with ActiveSupport conventions" do
    name = Charming::Generators::Name.new("weather_report")

    expect(name.class_name).to eq("WeatherReport")
    expect(name.controller_class_name).to eq("WeatherReportController")
    expect(name.component_class_name).to eq("WeatherReportComponent")
  end

  it "camelizes generated view action class names" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "weather_tui.gemspec"), "")
      generator = Charming::Generators::ViewGenerator.new(
        "forecast",
        ["user_settings"],
        out: StringIO.new,
        destination: dir
      )

      expect(generator.send(:action_class_name)).to eq("UserSettings")
    end
  end

  it "pluralizes generated model table names with ActiveSupport conventions" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "people_tui.gemspec"), "")
      generator = Charming::Generators::ModelGenerator.new("person", [], out: StringIO.new, destination: dir)

      expect(generator.send(:table_name)).to eq("people")
      expect(generator.send(:table_class_name)).to eq("People")
    end
  end
end
