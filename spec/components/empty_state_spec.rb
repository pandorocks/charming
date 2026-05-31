# frozen_string_literal: true

RSpec.describe Charming::Presentation::Components::EmptyState do
  it "renders a muted empty message" do
    state = described_class.new(message: "No stories loaded.")

    expect(state.render).to eq("\e[38;2;127;185;140;48;2;17;26;44mNo stories loaded.\e[0m")
  end

  it "renders a muted loading message" do
    state = described_class.new(loading: true, loading_message: "Loading feed")

    expect(state.render).to eq("\e[38;2;127;185;140;48;2;17;26;44mLoading feed\e[0m")
  end

  it "renders an error with optional help" do
    state = described_class.new(error: "Network failed", help: "Press r to retry.")

    expect(state.render).to eq("\e[38;2;255;179;71;48;2;17;26;44mNetwork failed\e[0m\n\e[38;2;127;185;140;48;2;17;26;44mPress r to retry.\e[0m")
  end

  it "uses an explicit error message when provided" do
    state = described_class.new(error: RuntimeError.new("boom"), error_message: "Could not load")

    expect(state.render).to eq("\e[38;2;255;179;71;48;2;17;26;44mCould not load\e[0m")
  end
end
