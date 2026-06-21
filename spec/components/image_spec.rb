# frozen_string_literal: true

RSpec.describe Charming::Components::Image do
  let(:kitty_terminal) { instance_double(Charming::Image::Terminal, protocol: :kitty, supports_graphics?: true) }
  let(:plain_terminal) { instance_double(Charming::Image::Terminal, protocol: :none, supports_graphics?: false) }

  def source(terminal)
    Charming::Image::Source.new(data: "png-bytes", terminal: terminal)
  end

  it "renders the placeholder block sized to rows x cols on a graphics terminal" do
    component = described_class.new(source: source(kitty_terminal), rows: 2, cols: 5)

    body = nil
    Charming::Escape.collecting { body = component.render }
    expect(body.lines.length).to eq(2)
    expect(Charming::UI::Width.measure(body.lines.first)).to eq(5)
  end

  it "registers the image transmission exactly once across repeated renders" do
    component = described_class.new(source: source(kitty_terminal), rows: 1, cols: 1)

    escapes = Charming::Escape.collecting do
      component.render
      component.render
    end

    expect(escapes.length).to eq(1)
    expect(escapes.first).to be_a(Charming::Image::Transmit)
  end

  it "renders the fallback string when the terminal lacks graphics support" do
    component = described_class.new(source: source(plain_terminal), rows: 2, cols: 5, fallback: "[image]")

    body = nil
    escapes = Charming::Escape.collecting { body = component.render }
    expect(body).to eq("[image]")
    expect(escapes).to be_empty
  end
end
