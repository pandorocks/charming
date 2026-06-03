# frozen_string_literal: true

RSpec.describe Charming::Layout do
  describe ".available_width" do
    it "subtracts reserved columns and clamps to a minimum" do
      screen = Charming::Screen.new(width: 40, height: 20)

      expect(described_class.available_width(screen, reserved: 28, min: 20)).to eq(20)
    end
  end

  describe ".available_height" do
    it "subtracts reserved rows and clamps to a maximum" do
      screen = Charming::Screen.new(width: 80, height: 30)

      expect(described_class.available_height(screen, reserved: 4, max: 20)).to eq(20)
    end
  end

  describe ".stack_or_row" do
    it "stacks blocks in narrow layouts" do
      expect(described_class.stack_or_row("A", "B", narrow: true, gap: 1)).to eq("A\n\nB")
    end

    it "joins blocks in wide layouts" do
      expect(described_class.stack_or_row("A", "B", narrow: false, gap: 1)).to eq("A B")
    end
  end

  describe ".selected_window_start" do
    it "keeps the selected item visible at the bottom of the window" do
      expect(described_class.selected_window_start(selected_index: 4, item_count: 10, window_size: 3)).to eq(2)
    end

    it "clamps near the end of the collection" do
      expect(described_class.selected_window_start(selected_index: 9, item_count: 10, window_size: 3)).to eq(7)
    end

    it "handles empty collections" do
      expect(described_class.selected_window_start(selected_index: 5, item_count: 0, window_size: 3)).to eq(0)
    end
  end
end
