# frozen_string_literal: true

RSpec.describe Charming::Components::Audio do
  it "renders a play glyph with the label while playing" do
    player = instance_double(Charming::Audio::Player, playing?: true)

    expect(described_class.new(player: player, label: "song.wav").render).to eq("▶ song.wav")
  end

  it "renders a stop glyph with the label when idle" do
    player = instance_double(Charming::Audio::Player, playing?: false)

    expect(described_class.new(player: player, label: "song.wav").render).to eq("■ song.wav")
  end

  it "renders only the glyph when no label is given" do
    player = instance_double(Charming::Audio::Player, playing?: true)

    expect(described_class.new(player: player).render).to eq("▶")
  end
end
