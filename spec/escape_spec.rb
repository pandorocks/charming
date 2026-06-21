# frozen_string_literal: true

RSpec.describe Charming::Escape do
  describe "collecting/register" do
    it "collects sequences registered during the block" do
      a = described_class.bell
      collected = described_class.collecting { described_class.register(a) }

      expect(collected).to eq([a])
    end

    it "ignores nil registrations and is a no-op outside a collection" do
      collected = described_class.collecting { described_class.register(nil) }

      expect(collected).to be_empty
      expect { described_class.register(described_class.bell) }.not_to raise_error
    end

    it "shadows an outer collection for the duration of an inner one" do
      inner = nil
      outer = described_class.collecting do
        described_class.register(described_class.bell)
        inner = described_class.collecting { described_class.register(described_class.title("x")) }
      end

      expect(outer.length).to eq(1)
      expect(inner.length).to eq(1)
    end
  end

  describe ".clipboard" do
    it "builds an OSC 52 sequence with base64-encoded text" do
      seq = described_class.clipboard("hello")

      expect(seq.payload).to eq("\e]52;c;#{["hello"].pack("m0")}\a")
      expect(seq.payload).to start_with("\e]52;c;")
    end

    it "round-trips arbitrary bytes through base64" do
      text = "secret \x00\x1b\x07 data"
      seq = described_class.clipboard(text)

      encoded = seq.payload[/\e\]52;c;([^\a]*)\a/, 1]
      expect(encoded.unpack1("m0")).to eq(text)
    end

    it "honors the target selection" do
      expect(described_class.clipboard("x", target: "p").payload).to start_with("\e]52;p;")
    end
  end

  describe ".notification" do
    it "uses OSC 9 for a body-only notification" do
      expect(described_class.notification("done").payload).to eq("\e]9;done\a")
    end

    it "uses OSC 777 when a title is given" do
      expect(described_class.notification("body", title: "Title").payload).to eq("\e]777;notify;Title;body\e\\")
    end

    it "strips control characters so text can't escape the sequence" do
      seq = described_class.notification("a\e]0;evil\ab")

      expect(seq.payload).to eq("\e]9;a]0;evilb\a")
    end
  end

  describe ".title" do
    it "builds an OSC 0 sequence and sanitizes the text" do
      expect(described_class.title("My App").payload).to eq("\e]0;My App\a")
      expect(described_class.title("x\ey").payload).to eq("\e]0;xy\a")
    end
  end

  describe ".bell" do
    it "is a bare BEL" do
      expect(described_class.bell.payload).to eq("\a")
    end
  end
end
