# frozen_string_literal: true

# End-to-end: an Image component rendered inside a view composed with `row`, driven through the real
# Runtime and a MemoryBackend. Verifies the out-of-band transmit reaches the backend (ahead of the
# frame), the placeholder cells land in the frame, layout width survives, and the transmit is sent once.
RSpec.describe "Image rendering through the Runtime" do
  before do
    stub_const("ImageSpecView", view_class)
    stub_const("ImageIntegrationController", controller_class)
    stub_const("ImageIntegrationApp", app_class)
  end

  let(:view_class) do
    Class.new(Charming::View) do
      def render
        image = Charming::Components::Image.new(source: source, rows: 2, cols: 3)
        row(render_component(image), count.to_s, gap: 1)
      end
    end
  end

  let(:controller_class) do
    Class.new(Charming::Controller) do
      key "r", :show
      key "q", :quit

      def show
        image = session[:image] ||= Charming::Image::Source.new(
          data: "PNGDATA",
          terminal: Charming::Image::Terminal.new(env: {"TERM" => "xterm-kitty"})
        )
        session[:count] = session[:count].to_i + 1
        render ImageSpecView.new(source: image, count: session[:count], screen: screen, controller: self)
      end
    end
  end

  let(:app_class) do
    Class.new(Charming::Application) do
      routes do
        root "image_integration#show"
      end
    end
  end

  def run(events)
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: events)
    Charming::Runtime.new(ImageIntegrationApp.new, backend: backend).run
    backend
  end

  it "flushes the image transmission to the backend before the frame that references it" do
    backend = run([Charming::Events::KeyEvent.new(key: :q)])

    expect(backend.escapes.length).to eq(1)
    transmit = backend.escapes.first
    expect(transmit).to be_a(Charming::Image::Transmit)
    expect(transmit.payload).to include("a=p,U=1")

    escape_index = backend.operations.index { |op| op.is_a?(Array) && op.first == :write_escape }
    frame_index = backend.operations.index { |op| op.is_a?(Array) && op.first == :write_frame }
    expect(escape_index).to be < frame_index
  end

  it "places the image's placeholder cells into the rendered frame, preserving layout width" do
    backend = run([Charming::Events::KeyEvent.new(key: :q)])

    frame = backend.frames.first
    expect(frame).to include(Charming::Image::Protocol::Kitty::PLACEHOLDER)
    # row of a 3-wide image + 1 gap + 1-wide label.
    expect(Charming::UI::Width.measure(frame.lines.first)).to eq(5)
  end

  it "transmits the image only once across re-renders" do
    backend = run([
      Charming::Events::KeyEvent.new(key: :r),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    expect(backend.frames.length).to be >= 2
    expect(backend.escapes.length).to eq(1)
  end
end
