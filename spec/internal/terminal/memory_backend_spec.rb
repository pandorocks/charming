# frozen_string_literal: true

RSpec.describe Charming::Internal::Terminal::MemoryBackend do
  let(:width) { 80 }
  let(:height) { 24 }

  it "returns events from the queue" do
    event = Charming::KeyEvent.new(key: :q)
    backend = described_class.new(events: [event])

    expect(backend.read_event).to eq(event)
  end

  it "returns mouse events from the queue" do
    event = Charming::MouseEvent.new(button: 0, x: 10, y: 5)
    backend = described_class.new(events: [event])

    expect(backend.read_event).to eq(event)
  end

  it "tracks frames and operations" do
    backend = described_class.new

    backend.write_frame("hello")

    expect(backend.frames).to eq(["hello"])
    expect(backend.operations).to include([:write_frame, "hello"])
  end

  it "tracks batched line updates as logical frames" do
    backend = described_class.new

    backend.write_frame("one\ntwo")
    backend.write_lines([[2, "TWO"]])

    expect(backend.frames).to eq(%W[one\ntwo one\nTWO])
    expect(backend.operations).to include([:write_lines, [[2, "TWO"]]])
  end

  it "tracks mouse tracking operations" do
    backend = described_class.new

    backend.enable_mouse_tracking
    backend.disable_mouse_tracking

    expect(backend.operations).to include(:enable_mouse_tracking)
    expect(backend.operations).to include(:disable_mouse_tracking)
    expect(backend.mouse_enabled?).to be false
  end

  it "returns size" do
    backend = described_class.new(width: 100, height: 30)

    expect(backend.size).to eq([100, 30])
  end
end
