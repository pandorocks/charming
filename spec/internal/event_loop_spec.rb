# frozen_string_literal: true

RSpec.describe Charming::Internal::EventLoop do
  def key_event(key)
    Charming::Events::KeyEvent.new(key: key)
  end

  def build_loop(backend:, task_queue: Thread::Queue.new, clock: -> { 0.0 }, **options)
    described_class.new(backend: backend, clock: clock, task_queue: task_queue, **options)
  end

  def pump(event_loop, quit_on: nil)
    seen = []
    event_loop.run do |event|
      seen << event
      :quit if quit_on&.call(event)
    end
    seen
  end

  it "yields backend input events in order until the backend is exhausted" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:a), key_event(:b)])

    seen = pump(build_loop(backend: backend))

    expect(seen.map(&:key)).to eq(%i[a b])
  end

  it "stops as soon as the block returns :quit" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q), key_event(:a)])

    seen = pump(build_loop(backend: backend), quit_on: ->(event) { event.key == :q })

    expect(seen.map(&:key)).to eq(%i[q])
  end

  it "stops when the interrupt check trips, even with input pending" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:a), key_event(:b)])
    interrupted = false
    event_loop = build_loop(backend: backend, interrupted: -> { interrupted })

    seen = []
    event_loop.run do |event|
      seen << event
      interrupted = true
      nil
    end

    expect(seen.map(&:key)).to eq(%i[a])
  end

  it "closes the task queue when the loop ends" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [])
    task_queue = Thread::Queue.new

    pump(build_loop(backend: backend, task_queue: task_queue))

    expect(task_queue).to be_closed
  end

  it "delivers queued task events before backend input" do
    backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:a)])
    task_queue = Thread::Queue.new
    task_event = Charming::Events::TaskEvent.new(name: :fetch, value: "done")
    task_queue << task_event

    seen = pump(build_loop(backend: backend, task_queue: task_queue))

    expect(seen.length).to eq(2)
    expect(seen.first).to eq(task_event)
    expect(seen.last.key).to eq(:a)
  end

  describe "timers" do
    let(:binding_class) { Struct.new(:name, :interval) }

    it "delivers a timer event when a timer comes due, before reading input" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [nil, key_event(:q)])
      times = [0.0, 0.0, 0.1, 0.2]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 0.2 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      expect(seen.first).to be_a(Charming::Events::TimerEvent)
      expect(seen.first.name).to eq(:tick)
    end

    it "reschedules a fired timer one interval ahead" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [nil, nil, key_event(:q)])
      times = [0.0, 0.0, 0.1, 0.1, 0.15, 0.25]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 0.25 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_events = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }
      expect(timer_events.length).to eq(2)
      expect(timer_events.first.now).to be < timer_events.last.now
    end

    it "caps input reads at the default timeout when no timers exist" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])

      pump(build_loop(backend: backend))

      expect(backend.operations).to include([:read_event, described_class::DEFAULT_READ_TIMEOUT])
    end

    it "shortens the input read timeout to the next timer's due time" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      event_loop = build_loop(
        backend: backend,
        clock: -> { 0.08 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      pump(event_loop)

      # Timer scheduled at 0.0 + wait, built at clock 0.08 → due at 0.18; 0.1 remaining clamps to 0.05.
      expect(backend.operations).to include([:read_event, described_class::DEFAULT_READ_TIMEOUT])
    end

    it "replaces scheduled timers on reset_timers" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [nil, key_event(:q)])
      times = [0.0, 0.0, 0.2, 0.3]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 0.3 },
        timer_bindings: [binding_class.new(:old, 0.1)]
      )
      event_loop.reset_timers([binding_class.new(:fresh, 0.1)])

      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_names = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }.map(&:name)
      expect(timer_names).to eq(%i[fresh])
    end
  end

  describe "input coalescing" do
    it "collapses identical key repeats into one delivered event when enabled" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [key_event(:up), key_event(:up), key_event(:up), key_event(:q)]
      )
      event_loop = build_loop(backend: backend, coalesce_input: true)

      seen = pump(event_loop, quit_on: ->(event) { event.key == :q })

      expect(seen.map(&:key)).to eq(%i[up q])
    end

    it "stashes a differing key behind a repeat burst instead of dropping it" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [key_event(:up), key_event(:up), key_event(:down), key_event(:q)]
      )
      event_loop = build_loop(backend: backend, coalesce_input: true)

      seen = pump(event_loop, quit_on: ->(event) { event.key == :q })

      expect(seen.map(&:key)).to eq(%i[up down q])
    end

    it "delivers every repeat when coalescing is off" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(
        events: [key_event(:up), key_event(:up), key_event(:q)]
      )

      seen = pump(build_loop(backend: backend), quit_on: ->(event) { event.key == :q })

      expect(seen.map(&:key)).to eq(%i[up up q])
    end
  end
end
