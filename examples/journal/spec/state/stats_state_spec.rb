# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Journal::StatsState do
  it "starts idle" do
    state = described_class.new
    expect(state.exporting).to be false
    expect(state.export_current).to eq(0)
  end
end
