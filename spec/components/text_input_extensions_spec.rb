# frozen_string_literal: true

RSpec.describe Charming::Components::TextInput do
  def key(name, char: nil)
    Charming::Events::KeyEvent.new(key: name, char: char)
  end

  describe "masked input" do
    it "renders asterisks instead of characters" do
      input = described_class.new(value: "secret", masked: true)
      expect(input.render).to eq("******|")
    end

    it "keeps the real value readable via #value" do
      input = described_class.new(value: "secret", masked: true)
      expect(input.value).to eq("secret")
    end

    it "masks newly typed characters" do
      input = described_class.new(masked: true)
      input.handle_key(key(:a, char: "a"))
      expect(input.render).to eq("*|")
      expect(input.value).to eq("a")
    end

    it "shows the placeholder unmasked when empty" do
      input = described_class.new(placeholder: "Password", masked: true)
      expect(input.render).to eq("|Password")
    end
  end

  describe "history recall" do
    let(:history) { ["first", "second", "third"] }

    it "recalls the most recent entry on up" do
      input = described_class.new(history: history)
      input.handle_key(key(:up))
      expect(input.value).to eq("third")
    end

    it "steps further back on repeated up" do
      input = described_class.new(history: history)
      input.handle_key(key(:up))
      input.handle_key(key(:up))
      expect(input.value).to eq("second")
    end

    it "stops at the oldest entry" do
      input = described_class.new(history: history)
      5.times { input.handle_key(key(:up)) }
      expect(input.value).to eq("first")
    end

    it "restores the draft when stepping forward past the newest entry" do
      input = described_class.new(value: "draft", history: history)
      input.handle_key(key(:up))
      expect(input.value).to eq("third")
      input.handle_key(key(:down))
      expect(input.value).to eq("draft")
    end

    it "moves the cursor to the end of the recalled value" do
      input = described_class.new(history: history)
      input.handle_key(key(:up))
      expect(input.cursor).to eq("third".length)
    end

    it "ignores up/down when no history is configured" do
      input = described_class.new(value: "abc")
      expect(input.handle_key(key(:up))).to be_nil
      expect(input.value).to eq("abc")
    end
  end
end
