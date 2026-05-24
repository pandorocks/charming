# frozen_string_literal: true

require "stringio"

RSpec.describe Charming::Internal::Terminal::TTYBackend do
  before do
    stub_const(
      "TTYBackendSpecReader",
      Class.new do
        attr_reader :console

        def initialize(keys:, keypresses: [])
          @console = Struct.new(:keys).new(keys)
          @keypresses = keypresses
        end

        def read_keypress(*)
          @keypresses.shift
        end
      end
    )

    stub_const(
      "TTYBackendSpecCursor",
      Class.new do
        def self.show
          "show"
        end

        def self.hide
          "hide"
        end

        def self.clear_screen
          "clear"
        end

        def self.move_to(column, row)
          "move:#{column}:#{row}"
        end
      end
    )

    stub_const(
      "TTYBackendSpecScreen",
      Class.new do
        def self.width = 120
        def self.height = 40
      end
    )

    stub_const("TTY::Screen", TTYBackendSpecScreen)
  end

  it "normalizes named keys from tty-reader" do
    reader = TTYBackendSpecReader.new(keys: { "\e[A" => :up }, keypresses: ["\e[A"])
    backend = described_class.new(input: StringIO.new, output: StringIO.new, reader: reader)

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::KeyEvent.new(key: :up))
  end

  it "normalizes return as enter" do
    reader = TTYBackendSpecReader.new(keys: { "\r" => :return }, keypresses: ["\r"])
    backend = described_class.new(input: StringIO.new, output: StringIO.new, reader: reader)

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::KeyEvent.new(key: :enter, char: "\n"))
  end

  it "normalizes printable characters" do
    reader = TTYBackendSpecReader.new(keys: {}, keypresses: ["q"])
    backend = described_class.new(input: StringIO.new, output: StringIO.new, reader: reader)

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::KeyEvent.new(key: "q", char: "q"))
  end

  it "preserves printable chars when tty-reader maps them as named keys" do
    reader = TTYBackendSpecReader.new(keys: { "q" => "q" }, keypresses: ["q"])
    backend = described_class.new(input: StringIO.new, output: StringIO.new, reader: reader)

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::KeyEvent.new(key: :q, char: "q"))
  end

  it "normalizes control-modified keys" do
    reader = TTYBackendSpecReader.new(keys: { "\u0003" => :ctrl_c }, keypresses: ["\u0003"])
    backend = described_class.new(input: StringIO.new, output: StringIO.new, reader: reader)

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::KeyEvent.new(key: :c, ctrl: true))
  end

  it "writes terminal control sequences" do
    output = StringIO.new
    backend = described_class.new(
      input: StringIO.new,
      output: output,
      reader: TTYBackendSpecReader.new(keys: {}),
      cursor: TTYBackendSpecCursor
    )

    backend.hide_cursor
    backend.clear
    backend.move_cursor(1, 1)
    backend.show_cursor

    expect(output.string).to eq("hideclearmove:0:0show")
  end

  it "returns a resize event after a resize notification" do
    backend = described_class.new(
      input: StringIO.new,
      output: StringIO.new,
      reader: TTYBackendSpecReader.new(keys: {})
    )

    backend.notify_resize

    expect(backend.read_event(timeout: 0.1)).to eq(Charming::ResizeEvent.new(width: 120, height: 40))
  end
end
