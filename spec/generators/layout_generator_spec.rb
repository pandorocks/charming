# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe Charming::Generators::LayoutGenerator do
  def with_app
    Dir.mktmpdir do |dir|
      Charming::Generators::AppGenerator.new("diary", out: StringIO.new, destination: dir).generate
      yield File.join(dir, "diary")
    end
  end

  def generate(app_root, args: [], out: StringIO.new, force: false)
    described_class.new("application", args, out: out, destination: app_root, force: force).generate
  end

  it "writes the sidebar application layout" do
    with_app do |app_root|
      out = StringIO.new

      generate(app_root, out: out)

      layout = File.read(File.join(app_root, "app/views/layouts/application_layout.rb"))
      expect(layout).to include("pane(:sidebar")
      expect(layout).to include("controller.sidebar_routes")
      expect(out.string).to include("overwrite app/views/layouts/application_layout.rb")
    end
  end

  it "restores the focus ring and command palette in ApplicationController" do
    with_app do |app_root|
      generate(app_root)

      controller = File.read(File.join(app_root, "app/controllers/application_controller.rb"))
      expect(controller).to include("focus_ring :sidebar, :content")
      expect(controller).to include('key "ctrl+p", :open_command_palette, scope: :global')
      expect(controller).to include('command "Theme", :open_theme_palette')
    end
  end

  it "registers the built-in themes in the application" do
    with_app do |app_root|
      generate(app_root)

      application = File.read(File.join(app_root, "lib/diary/application.rb"))
      expect(application).to include("Charming::UI::Theme.built_in_names.each do |theme_name|")
      expect(application).to include("default_theme :phosphor")
    end
  end

  it "inserts nothing twice when re-run" do
    with_app do |app_root|
      generate(app_root)
      out = StringIO.new

      generate(app_root, out: out)

      controller = File.read(File.join(app_root, "app/controllers/application_controller.rb"))
      application = File.read(File.join(app_root, "lib/diary/application.rb"))
      expect(controller.scan("focus_ring :sidebar, :content").size).to eq(1)
      expect(application.scan("default_theme :phosphor").size).to eq(1)
      expect(out.string).to include("identical app/views/layouts/application_layout.rb")
    end
  end

  it "refuses to overwrite a hand-modified layout" do
    with_app do |app_root|
      layout_path = File.join(app_root, "app/views/layouts/application_layout.rb")
      File.write(layout_path, "# custom layout\n")

      expect { generate(app_root) }.to raise_error(Charming::Generators::Error, /local changes/)
      expect(File.read(layout_path)).to eq("# custom layout\n")
    end
  end

  it "overwrites a hand-modified layout when forced" do
    with_app do |app_root|
      layout_path = File.join(app_root, "app/views/layouts/application_layout.rb")
      File.write(layout_path, "# custom layout\n")

      generate(app_root, force: true)

      expect(File.read(layout_path)).to include("pane(:sidebar")
    end
  end

  it "accepts the sidebar style in both flag forms" do
    with_app do |app_root|
      generate(app_root, args: ["--style", "sidebar"])
      generate(app_root, args: ["--style=sidebar"])

      layout = File.read(File.join(app_root, "app/views/layouts/application_layout.rb"))
      expect(layout).to include("pane(:sidebar")
    end
  end

  it "rejects unknown styles" do
    with_app do |app_root|
      expect { generate(app_root, args: ["--style", "neon"]) }
        .to raise_error(Charming::Generators::Error, /Unknown layout style: "neon"/)
    end
  end

  it "rejects stray positional arguments" do
    with_app do |app_root|
      expect { generate(app_root, args: ["sidebar"]) }
        .to raise_error(Charming::Generators::Error, /Usage: charming generate layout/)
    end
  end
end
