# frozen_string_literal: true

require "stringio"

RSpec.describe Charming::Internal::Terminal::KeyNormalizer do
  before do
    stub_const(
      "KeyNormalizerSpecReader",
      Class.new do
        attr_reader :console

        def initialize(keys:, keypresses: [])
          @console = Struct.new(:keys).new(keys)
          @keypresses = keypresses
        end
      end
    )
  end

  let(:reader_class) { KeyNormalizerSpecReader }

  def build(keys:, keypresses: [])
    reader = reader_class.new(keys: keys, keypresses: keypresses)
    described_class.new(reader)
  end

  it "maps a named arrow key from tty-reader" do
    normalizer = build(keys: {"\e[A" => :up})

    expect(normalizer.normalize("\e[A")).to eq(Charming::Events::KeyEvent.new(key: :up))
  end

  it "maps return to :enter with newline char" do
    normalizer = build(keys: {"\r" => :return})

    expect(normalizer.normalize("\r")).to eq(Charming::Events::KeyEvent.new(key: :enter, char: "\n"))
  end

  it "maps named keys through a printable character table (space)" do
    normalizer = build(keys: {})

    expect(normalizer.normalize(" ")).to eq(Charming::Events::KeyEvent.new(key: :" ", char: " "))
  end

  it "preserves printable chars when tty-reader maps them as named keys" do
    normalizer = build(keys: {"q" => "q"})

    expect(normalizer.normalize("q")).to eq(Charming::Events::KeyEvent.new(key: :q, char: "q"))
  end

  it "maps ctrl_X to ctrl: true" do
    normalizer = build(keys: {"" => :ctrl_c})

    expect(normalizer.normalize("")).to eq(Charming::Events::KeyEvent.new(key: :c, ctrl: true))
  end

  it "treats back_tab as shift+tab" do
    normalizer = build(keys: {"\e[Z" => :back_tab})

    expect(normalizer.normalize("\e[Z")).to eq(Charming::Events::KeyEvent.new(key: :tab, shift: true))
  end

  it "returns nil when keypress is nil" do
    normalizer = build(keys: {})

    expect(normalizer.normalize(nil)).to be_nil
  end

  it "preserves printable chars that aren't in the tty-reader keys table" do
    # When tty-reader has no entry, normalize falls through to character_event
    normalizer = build(keys: {})

    expect(normalizer.normalize("x")).to eq(Charming::Events::KeyEvent.new(key: :x, char: "x"))
  end
end
