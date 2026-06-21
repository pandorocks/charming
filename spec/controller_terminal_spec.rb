# frozen_string_literal: true

# The imperative terminal helpers (copy/notify/bell/set_title) registered during an action are
# collected by the Runtime and flushed to the backend as out-of-band escapes, ahead of the frame.
RSpec.describe "Controller terminal effects" do
  before do
    stub_const("TerminalFxController", controller_class)
    stub_const("TerminalFxApp", app_class)
  end

  let(:controller_class) do
    Class.new(Charming::Controller) do
      key "c", :do_effects
      key "q", :quit

      def show
        render "ready"
      end

      def do_effects
        copy("clipboard text")
        notify("Done", title: "TerminalFx")
        set_title("TerminalFx — c")
        render "did it"
      end
    end
  end

  let(:app_class) do
    Class.new(Charming::Application) do
      routes do
        root "terminal_fx#show"
      end
    end
  end

  def run(events)
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: events)
    Charming::Runtime.new(TerminalFxApp.new, backend: backend).run
    backend
  end

  it "flushes copy/notify/set_title sequences, ahead of the frame, only on the triggering action" do
    backend = run([
      Charming::Events::KeyEvent.new(key: :c),
      Charming::Events::KeyEvent.new(key: :q)
    ])

    payloads = backend.escapes.map(&:payload)
    expect(payloads).to include(
      a_string_starting_with("\e]52;c;"),
      "\e]777;notify;TerminalFx;Done\e\\",
      "\e]0;TerminalFx — c\a"
    )

    escape_index = backend.operations.index { |op| op.is_a?(Array) && op.first == :write_escape }
    frame_index = backend.operations.rindex { |op| op.is_a?(Array) && %i[write_frame write_lines].include?(op.first) }
    expect(escape_index).to be < frame_index
  end

  it "registers nothing on the initial render" do
    backend = run([Charming::Events::KeyEvent.new(key: :q)])

    expect(backend.escapes).to be_empty
  end
end
