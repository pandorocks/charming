# frozen_string_literal: true

RSpec.describe "counter example" do
  before(:context) do
    load File.expand_path("../../examples/counter.rb", __dir__)
  end

  it "renders the counter app" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(CounterApp.new, backend: backend).run

    expect(backend.frames.first).to include("Charming counter")
    expect(backend.frames.first).to include("Activity log")
  end

  it "records counter actions in the activity log" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :up),
        Charming::KeyEvent.new(key: :down),
        Charming::KeyEvent.new(key: :q)
      ]
    )

    Charming::Runtime.new(CounterApp.new, backend: backend).run

    expect(backend.frames.join("\n")).to include("Incremented to 1")
    expect(backend.frames.join("\n")).to include("Decremented to 0")
  end

  it "scrolls the activity log" do
    events = Array.new(7) { Charming::KeyEvent.new(key: :up) }
    events += Array.new(3) { Charming::KeyEvent.new(key: "j", char: "j") }
    events << Charming::KeyEvent.new(key: :q)
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: events)

    Charming::Runtime.new(CounterApp.new, backend: backend).run

    expect(backend.frames.last).to include("Incremented to 6")
  end

  it "uses backend dimensions when rendering the counter app" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)],
      width: 60,
      height: 12
    )

    Charming::Runtime.new(CounterApp.new, backend: backend).run

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

    Charming::Runtime.new(CounterApp.new, backend: backend).run

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

    Charming::Runtime.new(CounterApp.new, backend: backend).run

    expect(backend.frames.last).to include("Count: 1")
  end
end
