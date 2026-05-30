# frozen_string_literal: true

RSpec.describe "demo app example" do
  before(:context) do
    require File.expand_path("../../examples/demo_app/lib/demo_app", __dir__)
  end

  it "renders the generated demo app" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.first).to include("Charming demo")
    expect(backend.frames.first).to include("Activity log")
    expect(backend.frames.first).to include("- Ready")
  end

  it "animates the status spinner from timer events" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [nil, Charming::KeyEvent.new(key: :q)]
    )
    times = [0.0, 0.0, 0.0, 0.1, 0.1, 0.1]
    clock = -> { times.shift || 0.1 }

    Charming::Runtime.new(DemoApp::Application.new, backend: backend, clock: clock).run

    expect(backend.frames[0]).to include("- Ready")
    expect(backend.frames[1]).to include("\\ Ready")
  end

  it "records counter actions in the activity log" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :up),
        Charming::KeyEvent.new(key: :down),
        Charming::KeyEvent.new(key: :q)
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.join("\n")).to include("Incremented to 1")
    expect(backend.frames.join("\n")).to include("Decremented to 0")
  end

  it "scrolls the activity log" do
    events = Array.new(7) { Charming::KeyEvent.new(key: :up) }
    events += Array.new(3) { Charming::KeyEvent.new(key: "j", char: "j") }
    events << Charming::KeyEvent.new(key: :q)
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: events)

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.last).to include("Incremented to 6")
  end

  it "uses backend dimensions when rendering the demo app" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)],
      width: 60,
      height: 12
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.first.lines.count).to eq(12)
  end

  it "renders the command palette modal" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :p, char: "p"),
        Charming::KeyEvent.new(key: :escape),
        Charming::KeyEvent.new(key: :q, char: "q")
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.join("\n")).to include("Command palette")
  end

  it "auto-routes navigation keys to the focused log viewport via focus_ring" do
    base = Array.new(20) { Charming::KeyEvent.new(key: :up) } +
           [Charming::KeyEvent.new(key: :tab)]
    pre_end = base + [Charming::KeyEvent.new(key: :q)]
    post_end = base + [Charming::KeyEvent.new(key: :end), Charming::KeyEvent.new(key: :q)]

    pre = Charming::Internal::Terminal::MemoryBackend.new(events: pre_end)
    post = Charming::Internal::Terminal::MemoryBackend.new(events: post_end)
    Charming::Runtime.new(DemoApp::Application.new, backend: pre).run
    Charming::Runtime.new(DemoApp::Application.new, backend: post).run

    expect(pre.frames.last).not_to include("Incremented to 20")
    expect(post.frames.last).to include("Incremented to 20")
  end

  it "switches the bold border between counter and log when Tab cycles focus" do
    initial = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)]
    )
    after_tab = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :tab), Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: initial).run
    Charming::Runtime.new(DemoApp::Application.new, backend: after_tab).run

    # Thick border corners (┏ / ┓ / ┗ / ┛) mark the focused card; rounded
    # (╭ / ╮ / ╰ / ╯) mark unfocused cards. Initial focus is the counter card;
    # after Tab the log viewport card becomes the focused one.
    expect(initial.frames.last).to include("┏").and include("╭")
    expect(after_tab.frames.last).to include("┏").and include("╭")
    expect(initial.frames.last.index("┏")).to be < initial.frames.last.index("╭")
    expect(after_tab.frames.last.index("╭")).to be < after_tab.frames.last.index("┏")
  end

  it "selects a command from the palette with enter" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :p, char: "p"),
        Charming::KeyEvent.new(key: :enter, char: "\n"),
        Charming::KeyEvent.new(key: :q, char: "q")
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.last).to include("Count: 1")
  end
end
