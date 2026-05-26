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
