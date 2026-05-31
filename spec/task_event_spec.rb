# frozen_string_literal: true

RSpec.describe Charming::TaskEvent do
  it "defaults value and error to nil" do
    event = described_class.new(name: :fetch)

    expect(event.name).to eq(:fetch)
    expect(event.value).to be_nil
    expect(event.error).to be_nil
  end

  it "reports an error only when error is present" do
    expect(described_class.new(name: :fetch, value: "ok")).not_to be_error
    expect(described_class.new(name: :fetch, error: RuntimeError.new("boom"))).to be_error
  end
end
