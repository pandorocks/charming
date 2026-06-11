# frozen_string_literal: true

RSpec.describe Charming::Components::FuzzyMatcher do
  describe ".score" do
    it "matches subsequences" do
      expect(described_class.score("opl", "Open palette")).to be_a(Integer)
    end

    it "returns nil when characters are missing" do
      expect(described_class.score("xyz", "Open palette")).to be_nil
    end

    it "returns nil when characters are out of order" do
      expect(described_class.score("po", "op")).to be_nil
    end

    it "is case-insensitive" do
      expect(described_class.score("OPEN", "open palette")).not_to be_nil
    end

    it "scores contiguous matches above scattered ones" do
      contiguous = described_class.score("pal", "Open palette")
      scattered = described_class.score("pal", "Print all errors")
      expect(contiguous).to be > scattered
    end

    it "scores word-start matches above mid-word ones" do
      word_start = described_class.score("p", "Open palette")
      mid_word = described_class.score("p", "Wallpaper")
      expect(word_start).to be > mid_word
    end

    it "returns 0 for an empty query" do
      expect(described_class.score("", "anything")).to eq(0)
    end
  end

  describe ".filter" do
    it "orders results best-first" do
      candidates = ["Print all", "Open palette", "Help"]
      results = described_class.filter("pal", candidates)
      expect(results.first).to eq("Open palette")
      expect(results).not_to include("Help")
    end

    it "preserves original order on score ties" do
      results = described_class.filter("a", %w[alpha apple])
      expect(results).to eq(%w[alpha apple])
    end

    it "extracts labels via the block" do
      commands = [{label: "Quit"}, {label: "Query db"}]
      results = described_class.filter("qu", commands) { |c| c[:label] }
      expect(results.length).to eq(2)
      expect(results.first[:label]).to eq("Quit")
    end
  end

  describe "CommandPalette integration" do
    it "fuzzy-filters commands by subsequence" do
      commands = [
        Charming::Components::CommandPalette::Command.new(label: "Open theme palette", value: :a),
        Charming::Components::CommandPalette::Command.new(label: "Quit app", value: :b)
      ]
      palette = Charming::Components::CommandPalette.new(commands: commands, value: "otp")
      expect(palette.selected_command.label).to eq("Open theme palette")
    end

    it "returns no commands for non-matching queries" do
      commands = [Charming::Components::CommandPalette::Command.new(label: "Quit", value: :a)]
      palette = Charming::Components::CommandPalette.new(commands: commands, value: "zzz")
      expect(palette.render).to include("No commands found")
    end
  end
end
