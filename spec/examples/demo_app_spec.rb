# frozen_string_literal: true

RSpec.describe "demo app example" do
  before(:context) do
    require File.expand_path("../dummy/demo_app/lib/demo_app", __dir__)
  end

  it "renders the generated demo app" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.first).to include("DemoApp")
    expect(backend.frames.first).to include("Status: Idle")
    expect(backend.frames.first).to include("Tab content, then press r for async task.")
  end

  it "renders async loading and completed states" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :tab),
        Charming::KeyEvent.new(key: :r, char: "r"),
        Charming::KeyEvent.new(key: :q)
      ]
    )

    Charming::Runtime.new(
      DemoApp::Application.new,
      backend: backend,
      task_executor: completed_task_executor("Async task finished.")
    ).run

    frames = backend.frames.join("\n")
    expect(frames).to include("Status: Loading")
    expect(frames).to include("Status: Loaded")
    expect(frames).to include("Async task finished.")
  end

  it "advances the loading progress while the async task is running" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :tab),
        Charming::KeyEvent.new(key: :r, char: "r"),
        nil,
        Charming::KeyEvent.new(key: :q)
      ]
    )
    times = [0.0, 0.0, 0.05, 0.05, 0.1, 0.1, 0.2, 0.2, 0.3]

    Charming::Runtime.new(
      DemoApp::Application.new,
      backend: backend,
      clock: -> { times.shift || 0.3 },
      task_executor: pending_task_executor
    ).run

    frames = backend.frames.join("\n")
    stripped = Charming::UI::Width.strip_ansi(frames)
    expect(stripped).to include("[=                               ] Working")
    expect(stripped).to include("[==                              ] Working")
    expect(stripped).to include("a!2f$5C+8F%e1~9*B4&Ae%~1=b6Dc#1~ Working.")
  end

  it "does not run the async task when r is pressed while the sidebar is focused" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :r, char: "r"), Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(
      DemoApp::Application.new,
      backend: backend,
      task_executor: completed_task_executor("Async task finished.")
    ).run

    frames = backend.frames.join("\n")
    expect(frames).not_to include("Status: Loading")
    expect(frames).not_to include("Status: Loaded")
    expect(frames).not_to include("Async task finished.")
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

  it "preserves command palette input between generated demo app dispatches" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :p, char: "p"),
        Charming::KeyEvent.new(key: :q, char: "q"),
        Charming::KeyEvent.new(key: :escape),
        Charming::KeyEvent.new(key: :q, char: "q")
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.join("\n")).to include("q|")
    expect(backend.frames.join("\n")).to include("Quit app")
  end

  it "opens the generated demo app theme palette from the command palette" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :p, char: "p"),
        Charming::KeyEvent.new(key: :t, char: "t"),
        Charming::KeyEvent.new(key: :enter, char: "\n"),
        Charming::KeyEvent.new(key: :escape),
        Charming::KeyEvent.new(key: :q, char: "q")
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.join("\n")).to include("Search themes")
  end

  it "selects the bundled Phosphor theme from the command palette" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(
      events: [
        Charming::KeyEvent.new(key: :p, char: "p"),
        Charming::KeyEvent.new(key: :t, char: "t"),
        Charming::KeyEvent.new(key: :enter, char: "\n"),
        Charming::KeyEvent.new(key: :enter, char: "\n"),
        Charming::KeyEvent.new(key: :q, char: "q")
      ]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: backend).run

    expect(backend.frames.last).to include("\e[1;38;2;255;179;71;48;2;17;26;44m")
  end

  it "switches focus between sidebar and content when Tab cycles focus" do
    initial = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :q)]
    )
    after_tab = Charming::Internal::Terminal::MemoryBackend.new(
      events: [Charming::KeyEvent.new(key: :tab), Charming::KeyEvent.new(key: :q)]
    )

    Charming::Runtime.new(DemoApp::Application.new, backend: initial).run
    Charming::Runtime.new(DemoApp::Application.new, backend: after_tab).run

    expect(initial.frames.last).to include("> ● Home")
    expect(after_tab.frames.last).to include("  ● Home")
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

    expect(backend.frames.last).to include("DemoApp")
  end

  def completed_task_executor(value)
    lambda do |queue|
      Class.new do
        define_method(:submit) do |name|
          queue << Charming::TaskEvent.new(name: name, value: value)
          nil
        end

        def shutdown(timeout: 0.0)
        end
      end.new
    end
  end

  def pending_task_executor
    Class.new do
      def submit(name, &)
        nil
      end

      def shutdown(timeout: 0.0)
      end
    end.new
  end
end
