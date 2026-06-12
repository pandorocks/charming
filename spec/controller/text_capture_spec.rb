# frozen_string_literal: true

RSpec.describe "Text-capturing components and key dispatch priority" do
  let(:application) { Charming::Application.new }

  let(:controller_class) do
    Class.new(Charming::Controller) do
      focus_ring :note_form, :sidebar

      key "q", :quit, scope: :global
      key "?", :open_help_marker, scope: :global
      key "n", :content_action

      def show
        render "values: #{session.dig(:forms, :note, :values).inspect}"
      end

      def open_help_marker
        session[:help_marker] = true
        show
      end

      def content_action
        session[:content_fired] = true
        show
      end

      def note_form
        form(:note) do |f|
          f.input :title
          f.textarea :body
        end
      end

      def note_form_submitted(values)
        session[:submitted] = values
        show
      end
    end
  end

  before { stub_const("TextCaptureSpecController", controller_class) }

  def press(key, char: nil, ctrl: false, shift: false)
    TextCaptureSpecController
      .new(application: application, event: Charming::Events::KeyEvent.new(key: key, char: char, ctrl: ctrl, shift: shift))
      .dispatch_key
  end

  def form_values
    application.session.dig(:forms, :note, :values)
  end

  it "types q into the focused field instead of quitting" do
    response = press(:q, char: "q")

    expect(response.quit?).to be false
    expect(form_values[:title]).to eq("q")
  end

  it "types ? into the focused field instead of firing the global binding" do
    press(:"?", char: "?")

    expect(application.session[:help_marker]).to be_nil
    expect(form_values[:title]).to eq("?")
  end

  it "types characters bound as content keys into the field" do
    press(:n, char: "n")

    expect(application.session[:content_fired]).to be_nil
    expect(form_values[:title]).to eq("n")
  end

  it "keeps ctrl-modified shortcuts working while a field is focused" do
    # ctrl+q is unbound here; the point is it must NOT be inserted as text.
    press(:q, char: nil, ctrl: true)
    expect(form_values[:title]).to eq("")
  end

  it "routes tab to the form for field navigation before ring traversal" do
    press(:tab)

    state = application.session.dig(:forms, :note)
    expect(state[:focus_index]).to eq(1)
    # The controller ring must not have cycled to the sidebar.
    ctrl = TextCaptureSpecController.new(application: application)
    expect(ctrl.sidebar_focused?).to be false
  end

  it "still cycles the ring on tab when the focused component doesn't handle it" do
    viewer_class = Class.new(Charming::Controller) do
      focus_ring :pager, :sidebar

      def show = render("ok")

      def pager
        Charming::Components::Viewport.new(content: "line", height: 1)
      end
    end
    stub_const("PagerSpecController", viewer_class)

    PagerSpecController.new(application: application).dispatch(:show)
    PagerSpecController
      .new(application: application, event: Charming::Events::KeyEvent.new(key: :tab))
      .dispatch_key

    expect(PagerSpecController.new(application: application).sidebar_focused?).to be true
  end

  it "still quits on q when no text component is focused" do
    plain_class = Class.new(Charming::Controller) do
      key "q", :quit, scope: :global
      def show = render("ok")
    end
    stub_const("PlainSpecController", plain_class)

    response = PlainSpecController
      .new(application: application, event: Charming::Events::KeyEvent.new(key: :q, char: "q"))
      .dispatch_key

    expect(response.quit?).to be true
  end
end
