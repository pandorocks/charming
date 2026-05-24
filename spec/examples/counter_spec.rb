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
