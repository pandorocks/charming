# frozen_string_literal: true

RSpec.describe Charming::ApplicationState do
  it "supports typed attributes with defaults" do
    stub_const("ApplicationStateSpecCounter", Class.new(described_class) do
      attribute :count, :integer, default: 0
    end)

    expect(ApplicationStateSpecCounter.new.count).to eq(0)
    expect(ApplicationStateSpecCounter.new(count: "2").count).to eq(2)
  end

  it "supports ActiveModel validations" do
    stub_const("ApplicationStateSpecProfile", Class.new(described_class) do
      attribute :name, :string
      validates :name, presence: true
    end)

    instance = ApplicationStateSpecProfile.new

    expect(instance).not_to be_valid
    expect(instance.errors[:name]).to include("can't be blank")
  end
end
