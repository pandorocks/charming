# frozen_string_literal: true

RSpec.describe Charming::Image::Terminal do
  def terminal(env)
    described_class.new(env: env)
  end

  it "detects Kitty via KITTY_WINDOW_ID" do
    expect(terminal("KITTY_WINDOW_ID" => "1").protocol).to eq(:kitty)
  end

  it "detects Kitty via TERM" do
    expect(terminal("TERM" => "xterm-kitty").protocol).to eq(:kitty)
  end

  it "detects Ghostty via TERM" do
    expect(terminal("TERM" => "xterm-ghostty").protocol).to eq(:kitty)
  end

  it "detects Ghostty via TERM_PROGRAM" do
    expect(terminal("TERM_PROGRAM" => "ghostty").protocol).to eq(:kitty)
  end

  it "detects Ghostty via GHOSTTY_RESOURCES_DIR" do
    expect(terminal("GHOSTTY_RESOURCES_DIR" => "/opt/ghostty").protocol).to eq(:kitty)
  end

  it "reports :none for an unrecognized terminal" do
    expect(terminal("TERM" => "xterm-256color").protocol).to eq(:none)
  end

  it "reports :none for an empty environment" do
    expect(terminal({}).protocol).to eq(:none)
  end

  it "answers supports_graphics? from the detected protocol" do
    expect(terminal("KITTY_WINDOW_ID" => "1").supports_graphics?).to be(true)
    expect(terminal({}).supports_graphics?).to be(false)
  end
end
