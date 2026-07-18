# frozen_string_literal: true

RSpec.describe Charming::Components::Progressbar do
  it "colors the filled region with a gradient sweep across the bar" do
    bar = described_class.new(total: 3, gradient: ["#000000", "#ffffff"])
    bar.update(2)

    expect(bar.render).to eq("[\e[38;2;0;0;0m=\e[0m\e[38;2;128;128;128m=\e[0m ]")
  end

  it "reports completion as a percentage" do
    bar = described_class.new(total: 4)
    bar.update(1)

    expect(bar.percent).to eq(25)
  end
  describe "#initialize" do
    it "defaults current to 0" do
      pb = described_class.new(total: 10)
      expect(pb.current).to eq(0)
    end

    it "accepts total as keyword argument" do
      pb = described_class.new(total: 5)
      expect(pb.total).to eq(5)
    end

    it "defaults label to nil" do
      pb = described_class.new(total: 10)
      expect(pb.label).to be_nil
    end

    it "accepts a custom label" do
      pb = described_class.new(total: 10, label: "Loading")
      expect(pb.label).to eq("Loading")
    end

    it "requires total keyword argument" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe "#render" do
    context "determinate" do
      it "renders bar at 0%" do
        pb = described_class.new(total: 10)
        expect(pb.render).to eq("[" + " " * 10 + "]")
      end

      it "renders bar at 50%" do
        pb = described_class.new(total: 10)
        pb.tick(5)
        expect(pb.render).to eq("[" + "=" * 5 + " " * 5 + "]")
      end

      it "renders bar at 100%" do
        pb = described_class.new(total: 10)
        pb.tick(10)
        expect(pb.render).to eq("[" + "=" * 10 + "]")
      end

      it "includes label when provided" do
        pb2 = described_class.new(total: 10, label: "Loading")
        pb2.tick(5)
        expect(pb2.render).to include("Loading")
      end

      it "renders custom complete/incomplete characters" do
        pb3 = described_class.new(total: 4, complete: "#", incomplete: ".")
        pb3.tick(2)
        expect(pb3.render).to eq("[" + "#" * 2 + "." * 2 + "]")
      end

      it "handles single item total" do
        pb_single = described_class.new(total: 1)
        pb_single.tick(1)
        expect(pb_single.render).to eq("[=]")
      end

      it "handles zero total gracefully" do
        pb_zero = described_class.new(total: 0)
        expect { pb_zero.render }.not_to raise_error
      end
    end
  end

  describe "#tick" do
    it "advances by count (defaults to 1)" do
      pb = described_class.new(total: 10)
      pb.tick
      expect(pb.current).to eq(1)
    end

    it "advances by given count" do
      pb = described_class.new(total: 10)
      pb.tick(3)
      expect(pb.current).to eq(3)
    end

    it "returns self for chaining" do
      pb = described_class.new(total: 10)
      expect(pb.tick(2)).to eq(pb)
    end

    it "clamps at total" do
      pb = described_class.new(total: 10)
      pb.tick(15)
      expect(pb.current).to be <= 10
    end

    it "chains multiple ticks" do
      pb = described_class.new(total: 10)
      pb.tick(3).tick(4)
      expect(pb.current).to eq(7)
    end
  end

  describe "#update" do
    it "sets exact position" do
      pb = described_class.new(total: 10)
      pb.update(5)
      expect(pb.current).to eq(5)
    end

    it "clamps below 0" do
      pb = described_class.new(total: 10)
      pb.update(-2)
      expect(pb.current).to be >= 0
    end

    it "clamps above total" do
      pb = described_class.new(total: 10)
      pb.update(15)
      expect(pb.current).to be <= 10
    end

    it "returns self for chaining" do
      pb = described_class.new(total: 10)
      expect(pb.update(3)).to eq(pb)
    end
  end

  describe "#complete!" do
    it "sets current to total" do
      pb = described_class.new(total: 10, label: "Done")
      pb.tick(5).complete!
      expect(pb.current).to eq(10)
    end

    it "renders bar at full width after complete!" do
      pb = described_class.new(total: 6)
      pb.complete!
      output = pb.render
      expect(output).to eq("[" + "=" * 6 + "]")
    end
  end
end
