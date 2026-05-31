# frozen_string_literal: true

RSpec.describe Charming::UI::Width do
  it "measures Unicode display width" do
    expect(described_class.measure("界")).to eq(2)
  end

  it "ignores ANSI escape sequences" do
    expect(described_class.measure("\e[31mHi\e[0m")).to eq(2)
  end
end
