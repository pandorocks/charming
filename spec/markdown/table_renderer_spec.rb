# frozen_string_literal: true

RSpec.describe Charming::Markdown::TableRenderer do
  it "renders rows with padded columns and a header separator" do
    style = Charming::Markdown::StyleConfig.builtin(:dark)[:table]
    renderer = described_class.new(rows: [["Name", "Value"], ["One", "1"]], style: style)

    expect(renderer.render).to eq(<<~TEXT.chomp)
      | Name | Value |
      |------|-------|
      | One  | 1     |
    TEXT
  end

  it "renders nothing for empty rows" do
    style = Charming::Markdown::StyleConfig.builtin(:dark)[:table]
    renderer = described_class.new(rows: [], style: style)

    expect(renderer.render).to eq("")
  end
end
