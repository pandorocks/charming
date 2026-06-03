# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe "template rendering" do
  def write_template(root, path, content)
    absolute_path = File.join(root, "app", "views", path)
    FileUtils.mkdir_p(File.dirname(absolute_path))
    File.write(absolute_path, content)
  end

  it "renders ERB templates with assigns and view helpers" do
    Dir.mktmpdir do |dir|
      write_template(dir, "greeting.tui.erb", '<%= text "Hello #{name}", style: style.bold %>')

      template = Charming::Templates.resolve("greeting", root: dir)
      view = Charming::TemplateView.new(template: template, name: "Ruby")

      expect(view.render).to eq("\e[1mHello Ruby\e[0m")
    end
  end

  it "prefers tui.erb before txt.erb" do
    Dir.mktmpdir do |dir|
      write_template(dir, "message.tui.erb", "TUI")
      write_template(dir, "message.txt.erb", "TXT")

      template = Charming::Templates.resolve("message", root: dir)

      expect(Charming::TemplateView.new(template: template).render).to eq("TUI")
    end
  end

  it "renders txt.erb templates" do
    Dir.mktmpdir do |dir|
      write_template(dir, "message.txt.erb", "Hello <%= name %>")

      template = Charming::Templates.resolve("message", root: dir)

      expect(Charming::TemplateView.new(template: template, name: "Ruby").render).to eq("Hello Ruby")
    end
  end

  it "raises a useful error when a template is missing" do
    Dir.mktmpdir do |dir|
      expect { Charming::Templates.resolve("missing", root: dir) }.to raise_error(
        Charming::Templates::MissingTemplateError,
        /missing.*missing\.tui\.erb.*missing\.txt\.erb/
      )
    end
  end

  it "renders controller action templates through template layouts" do
    Dir.mktmpdir do |dir|
      write_template(dir, "template_spec/show.tui.erb", '<%= text "Hello #{name}" %>')
      write_template(dir, "layouts/application.tui.erb", "Layout(<%= yield_content %> / <%= name %>)")
      application_class = Class.new(Charming::Application) { root dir }
      stub_const("TemplateSpecController", Class.new(Charming::Controller) do
        layout "layouts/application"

        def show
          render :show, name: "Ruby"
        end
      end)

      response = TemplateSpecController.new(application: application_class.new).dispatch(:show)

      expect(response.body).to eq("Layout(Hello Ruby / Ruby)")
    end
  end

  it "renders conventional Ruby view classes before ERB templates" do
    Dir.mktmpdir do |dir|
      write_template(dir, "home/show.tui.erb", "ERB")
      stub_const("ClassViewSpec", Module.new)
      stub_const("ClassViewSpec::Application", Class.new(Charming::Application) { root dir })
      stub_const("ClassViewSpec::Home", Module.new)
      stub_const("ClassViewSpec::Home::ShowView", Class.new(Charming::View) do
        def render
          "Class #{name}"
        end
      end)
      stub_const("ClassViewSpec::HomeController", Class.new(Charming::Controller) do
        def show
          render :show, name: "Ruby"
        end
      end)

      response = ClassViewSpec::HomeController.new(application: ClassViewSpec::Application.new).dispatch(:show)

      expect(response.body).to eq("Class Ruby")
    end
  end

  it "falls back to ERB templates when no conventional Ruby view class exists" do
    Dir.mktmpdir do |dir|
      write_template(dir, "home/show.tui.erb", "ERB <%= name %>")
      stub_const("FallbackViewSpec", Module.new)
      stub_const("FallbackViewSpec::Application", Class.new(Charming::Application) { root dir })
      stub_const("FallbackViewSpec::HomeController", Class.new(Charming::Controller) do
        def show
          render :show, name: "Ruby"
        end
      end)

      response = FallbackViewSpec::HomeController.new(application: FallbackViewSpec::Application.new).dispatch(:show)

      expect(response.body).to eq("ERB Ruby")
    end
  end

  it "renders class layouts with rendered content and assigns" do
    stub_const("ClassLayoutSpec", Module.new)
    stub_const("ClassLayoutSpec::Application", Class.new(Charming::Application))
    stub_const("ClassLayoutSpec::Layouts", Module.new)
    stub_const("ClassLayoutSpec::Layouts::ApplicationLayout", Class.new(Charming::View) do
      def render
        "Layout(#{yield_content} / #{name})"
      end
    end)
    stub_const("ClassLayoutSpec::Home", Module.new)
    stub_const("ClassLayoutSpec::Home::ShowView", Class.new(Charming::View) do
      def render
        "Hello #{name}"
      end
    end)
    stub_const("ClassLayoutSpec::HomeController", Class.new(Charming::Controller) do
      layout ClassLayoutSpec::Layouts::ApplicationLayout

      def show
        render :show, name: "Ruby"
      end
    end)

    response = ClassLayoutSpec::HomeController.new(application: ClassLayoutSpec::Application.new).dispatch(:show)

    expect(response.body).to eq("Layout(Hello Ruby / Ruby)")
  end

  it "renders explicit template paths from controllers" do
    Dir.mktmpdir do |dir|
      write_template(dir, "custom/page.txt.erb", "Explicit <%= name %>")
      application_class = Class.new(Charming::Application) { root dir }
      controller_class = Class.new(Charming::Controller) do
        def show
          render_template "custom/page", name: "Ruby"
        end
      end

      response = controller_class.new(application: application_class.new).dispatch(:show)

      expect(response.body).to eq("Explicit Ruby")
    end
  end
end
