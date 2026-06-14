# frozen_string_literal: true

# A fake System adapter: records spawned commands and process control without
# touching the real process table or shelling out.
class FakeAudioSystem
  attr_reader :spawned, :terminated, :waited

  def initialize(available: [], macos: false, linux: false)
    @available = available
    @macos = macos
    @linux = linux
    @spawned = []
    @terminated = []
    @waited = []
    @alive = {}
    @next_pid = 1000
  end

  def macos? = @macos

  def linux? = @linux

  def which?(command) = @available.include?(command)

  def spawn(argv)
    @spawned << argv
    pid = (@next_pid += 1)
    @alive[pid] = true
    pid
  end

  def terminate(pid)
    @terminated << pid
    @alive[pid] = false
  end

  def alive?(pid) = @alive.fetch(pid, false)

  def wait(pid)
    @waited << pid
    @alive[pid] = false
  end

  # Test helper: simulate the sound finishing on its own.
  def finish(pid) = @alive[pid] = false
end

RSpec.describe Charming::Audio::Player do
  it "prefers ffplay over native backends on any platform" do
    system = FakeAudioSystem.new(available: %w[ffplay afplay], macos: true)
    player = described_class.new(system: system)

    player.play("song.wav")

    expect(system.spawned.last).to eq(["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", "song.wav"])
  end

  it "falls back to afplay on macOS when ffplay is absent" do
    system = FakeAudioSystem.new(available: %w[afplay], macos: true)
    player = described_class.new(system: system)

    player.play("song.wav")

    expect(system.spawned.last).to eq(["afplay", "song.wav"])
  end

  it "prefers paplay over other Linux backends" do
    system = FakeAudioSystem.new(available: %w[paplay mpg123 aplay], linux: true)
    player = described_class.new(system: system)

    player.play("song.wav")

    expect(system.spawned.last).to eq(["paplay", "song.wav"])
  end

  it "falls through the Linux backends in order" do
    system = FakeAudioSystem.new(available: %w[mpg123 aplay], linux: true)
    player = described_class.new(system: system)

    player.play("song.wav")

    expect(system.spawned.last).to eq(["mpg123", "-q", "song.wav"])
  end

  it "ignores backends meant for the other platform" do
    system = FakeAudioSystem.new(available: %w[afplay], linux: true)
    player = described_class.new(system: system)

    expect { player.play("song.wav") }.to raise_error(described_class::Unavailable)
  end

  it "raises Unavailable when no backend is installed" do
    system = FakeAudioSystem.new(available: [], macos: true)
    player = described_class.new(system: system)

    expect { player.play("song.wav") }.to raise_error(described_class::Unavailable, /no audio player/)
  end

  it "reports availability without playing" do
    expect(described_class.new(system: FakeAudioSystem.new(available: %w[ffplay], macos: true)).available?).to be(true)
    expect(described_class.new(system: FakeAudioSystem.new(available: [], macos: true)).available?).to be(false)
  end

  it "tracks playback state and stops the process" do
    system = FakeAudioSystem.new(available: %w[ffplay], macos: true)
    player = described_class.new(system: system)

    pid = player.play("song.wav")
    expect(player.playing?).to be(true)

    player.stop
    expect(system.terminated).to include(pid)
    expect(player.playing?).to be(false)
  end

  it "reports not playing once the sound finishes on its own" do
    system = FakeAudioSystem.new(available: %w[ffplay], macos: true)
    player = described_class.new(system: system)

    pid = player.play("song.wav")
    system.finish(pid)

    expect(player.playing?).to be(false)
  end

  it "stops a previous sound before starting a new one" do
    system = FakeAudioSystem.new(available: %w[ffplay], macos: true)
    player = described_class.new(system: system)

    first = player.play("a.wav")
    player.play("b.wav")

    expect(system.terminated).to include(first)
    expect(system.spawned.length).to eq(2)
  end

  it "waits for the current sound and clears it" do
    system = FakeAudioSystem.new(available: %w[ffplay], macos: true)
    player = described_class.new(system: system)

    pid = player.play("song.wav")
    player.wait

    expect(system.waited).to include(pid)
    expect(player.playing?).to be(false)
  end
end
