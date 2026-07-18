# frozen_string_literal: true

RSpec.describe Charming::Components::Paginator do
  it "computes page count from total and per_page" do
    paginator = described_class.new(total: 10, per_page: 4)

    expect(paginator.page_count).to eq(3)
  end

  it "slices the current page's items" do
    paginator = described_class.new(total: 5, per_page: 2, page: 1)

    expect(paginator.page_items(%w[a b c d e])).to eq(%w[c d])
  end

  it "moves between pages, clamping at the ends" do
    paginator = described_class.new(total: 5, per_page: 2)

    paginator.next_page
    paginator.next_page
    paginator.next_page

    expect(paginator.page).to eq(2)

    paginator.prev_page
    expect(paginator.page).to eq(1)
  end

  it "renders bubbles-style dots with the active page marked" do
    paginator = described_class.new(total: 6, per_page: 2, page: 1)

    expect(paginator.render).to eq("○ ● ○")
  end

  it "renders arabic format on request" do
    paginator = described_class.new(total: 6, per_page: 2, page: 1, format: :arabic)

    expect(paginator.render).to eq("2/3")
  end

  it "treats an empty collection as a single page" do
    paginator = described_class.new(total: 0, per_page: 5)

    expect(paginator.page_count).to eq(1)
    expect(paginator.render).to eq("●")
  end
end
