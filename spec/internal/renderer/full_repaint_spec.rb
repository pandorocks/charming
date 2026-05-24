# frozen_string_literal: true

RSpec.describe Charming::Internal::Renderer::FullRepaint do
  it "clears, moves home, and writes the full frame" do
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
end
