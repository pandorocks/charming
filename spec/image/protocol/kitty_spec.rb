# frozen_string_literal: true

RSpec.describe Charming::Image::Protocol::Kitty do
  describe ".transmit" do
    it "builds an APC transmit followed by a virtual placement" do
      payload = described_class.transmit(image_id: 42, png_bytes: "abc", rows: 3, cols: 4)

      expect(payload).to start_with("\e_G")
      expect(payload).to include("a=t", "f=100", "t=d", "i=42", "q=2")
      expect(payload).to include("\e_Ga=p,U=1,i=42,c=4,r=3,q=2\e\\")
      expect(payload).to end_with("\e\\")
    end

    it "chunks base64 data into <=4096-byte pieces, flagging all but the last with m=1" do
      bytes = "x" * 10_000
      payload = described_class.transmit(image_id: 1, png_bytes: bytes, rows: 1, cols: 1)

      transmit = payload.split("\e_Ga=p").first
      chunks = transmit.scan(/\e_G[^;]*;([^\e]*)\e\\/).map(&:first)
      expect(chunks.length).to be > 1
      expect(transmit.scan("m=1").length).to eq(chunks.length - 1)
      expect(transmit).to include("m=0;")
    end

    it "round-trips the original bytes through the base64 chunks" do
      bytes = "the original PNG bytes \x00\x01\x02".b * 500
      payload = described_class.transmit(image_id: 1, png_bytes: bytes, rows: 1, cols: 1)

      transmit = payload.split("\e_Ga=p").first
      decoded = transmit.scan(/\e_G[^;]*;([^\e]*)\e\\/).map(&:first).join.unpack1("m0")
      expect(decoded).to eq(bytes)
    end

    it "emits a single chunk for tiny images" do
      payload = described_class.transmit(image_id: 1, png_bytes: "x", rows: 1, cols: 1)
      transmit = payload.split("\e_Ga=p").first

      expect(transmit.scan("\e_G").length).to eq(1)
      expect(transmit).to include("m=0;")
    end
  end

  describe ".placeholder_block" do
    it "produces rows lines that each measure exactly cols display columns" do
      block = described_class.placeholder_block(image_id: 0xAABBCC, rows: 3, cols: 5)
      lines = block.lines(chomp: true)

      expect(lines.length).to eq(3)
      lines.each { |line| expect(Charming::UI::Width.measure(line)).to eq(5) }
    end

    it "fills each cell with the placeholder code point and its row/column diacritics" do
      block = described_class.placeholder_block(image_id: 1, rows: 2, cols: 2)
      stripped = Charming::UI::Width.strip_ansi(block.lines(chomp: true).first)

      expect(stripped).to include(described_class::PLACEHOLDER)
      expect(stripped.scan(/\X/).length).to eq(2) # two width-1 cells
    end

    it "carries the image id as an exact truecolor foreground, immune to color downconversion" do
      original = Charming::UI::ColorSupport.level
      Charming::UI::ColorSupport.level = :color16

      block = described_class.placeholder_block(image_id: 0xAABBCC, rows: 1, cols: 1)
      expect(block).to include("\e[38;2;170;187;204m")
    ensure
      Charming::UI::ColorSupport.level = original
    end

    it "raises when a dimension exceeds the encodable cell range" do
      oversized = described_class::DIACRITICS.length + 1
      expect { described_class.placeholder_block(image_id: 1, rows: oversized, cols: 1) }
        .to raise_error(ArgumentError, /at most/)
    end
  end

  describe ".delete" do
    it "builds an APC delete that frees the image's data and placements" do
      expect(described_class.delete(image_id: 42)).to eq("\e_Ga=d,d=I,i=42,q=2\e\\")
    end
  end

  describe "DIACRITICS" do
    it "provides the full Kitty row/column table" do
      expect(described_class::DIACRITICS.length).to eq(297)
      expect(described_class::DIACRITIC_CODEPOINTS.first).to eq(0x0305)
    end
  end
end
