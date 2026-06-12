# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Journal::Entry do
  it "requires a title" do
    entry = described_class.new(mood: "good", body: "x")
    expect(entry).not_to be_valid
    expect(entry.errors[:title]).to include("can't be blank")
  end

  it "requires a known mood" do
    entry = described_class.new(title: "t", mood: "ecstatic")
    expect(entry).not_to be_valid
  end

  it "persists and orders recent-first" do
    older = described_class.create!(title: "old", mood: "meh", created_at: Time.now - 86_400)
    newer = described_class.create!(title: "new", mood: "good")
    expect(described_class.recent_first.first(2)).to eq([newer, older])
  end

  it "builds a list label with date, mood, and favorite star" do
    entry = described_class.create!(title: "Starred", mood: "good", favorite: true)
    expect(entry.list_label).to include("😄")
    expect(entry.list_label).to include("Starred ★")
  end
end
