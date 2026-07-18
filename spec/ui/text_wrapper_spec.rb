# frozen_string_literal: true

RSpec.describe Charming::UI::TextWrapper do
  it "returns text unchanged without a width" do
    wrapper = described_class.new(width: nil)

    expect(wrapper.wrap("Alpha beta")).to eq("Alpha beta")
  end

  it "wraps a single line at word boundaries" do
    wrapper = described_class.new(width: 10)

    expect(wrapper.wrap("Alpha beta gamma")).to eq("Alpha beta\ngamma")
  end

  it "wraps each line independently" do
    wrapper = described_class.new(width: 6)

    expect(wrapper.wrap("One two\nThree four")).to eq("One\ntwo\nThree\nfour")
  end

  it "leaves short lines unchanged" do
    wrapper = described_class.new(width: 20)

    expect(wrapper.wrap("Short line")).to eq("Short line")
  end
end
