# frozen_string_literal: true

RSpec.describe Charming::Internal::Renderer::Differential do
  it "full repaints the initial frame" do
    backend = Charming::Internal::Terminal::MemoryBackend.new

    described_class.new(backend).render("hello")

    expect(backend.operations).to eq(
      [
        :clear,
        [:move_cursor, 1, 1],
        [:write_frame, "hello"]
      ]
    )
  end

  it "skips identical frames" do
    backend = Charming::Internal::Terminal::MemoryBackend.new
    renderer = described_class.new(backend)

    renderer.render("hello")
    renderer.render("hello")

    expect(backend.frames).to eq(["hello"])
    expect(backend.operations).to eq(
      [
        :clear,
        [:move_cursor, 1, 1],
        [:write_frame, "hello"]
      ]
    )
  end

  it "updates from the first changed line through the frame end" do
    backend = Charming::Internal::Terminal::MemoryBackend.new
    renderer = described_class.new(backend)

    renderer.render("one\ntwo\nthree")
    renderer.render("one\nTWO\nthree")

    expect(backend.frames).to eq(%W[one\ntwo\nthree one\nTWO\nthree])
    expect(backend.operations.last).to eq([:write_lines, [[2, "TWO"], [3, "three"]]])
  end

  it "clears lines removed by shorter frames" do
    backend = Charming::Internal::Terminal::MemoryBackend.new
    renderer = described_class.new(backend)

    renderer.render("one\ntwo\nthree")
    renderer.render("one")

    expect(backend.frames.last).to eq("one")
    expect(backend.operations.last).to eq([:write_lines, [[2, ""], [3, ""]]])
  end
end
