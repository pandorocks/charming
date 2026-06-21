# frozen_string_literal: true

RSpec.describe Charming::Image::Source do
  let(:kitty_terminal) { instance_double(Charming::Image::Terminal, protocol: :kitty, supports_graphics?: true) }
  let(:plain_terminal) { instance_double(Charming::Image::Terminal, protocol: :none, supports_graphics?: false) }

  it "requires either a path or data" do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it "derives a stable, nonzero 24-bit image id from the bytes" do
    source = described_class.new(data: "png-bytes", terminal: kitty_terminal)

    expect(source.image_id).to eq(source.image_id)
    expect(source.image_id).to be_between(1, 0xFFFFFF)
  end

  it "differs in id for different bytes" do
    a = described_class.new(data: "one", terminal: kitty_terminal)
    b = described_class.new(data: "two", terminal: kitty_terminal)

    expect(a.image_id).not_to eq(b.image_id)
  end

  it "honors an explicit id" do
    expect(described_class.new(data: "x", id: 7, terminal: kitty_terminal).image_id).to eq(7)
  end

  it "builds a Transmit carrying the image id and a Kitty payload when graphics are supported" do
    source = described_class.new(data: "x", id: 9, terminal: kitty_terminal)
    transmit = source.transmit(rows: 2, cols: 3)

    expect(transmit).to be_a(Charming::Image::Transmit)
    expect(transmit.image_id).to eq(9)
    expect(transmit.payload).to include("i=9", "a=p,U=1,i=9,c=3,r=2")
  end

  it "builds a placeholder block sized to rows x cols when graphics are supported" do
    source = described_class.new(data: "x", terminal: kitty_terminal)

    expect(source.placement(rows: 2, cols: 4).lines.length).to eq(2)
  end

  it "is a no-op on terminals without graphics support" do
    source = described_class.new(data: "x", terminal: plain_terminal)

    expect(source.supports_graphics?).to be(false)
    expect(source.transmit(rows: 1, cols: 1)).to be_nil
    expect(source.placement(rows: 1, cols: 1)).to eq("")
  end

  it "gates retransmission via transmitted?/mark_transmitted" do
    source = described_class.new(data: "x", terminal: kitty_terminal)

    expect(source.transmitted?).to be(false)
    source.mark_transmitted
    expect(source.transmitted?).to be(true)
  end
end
