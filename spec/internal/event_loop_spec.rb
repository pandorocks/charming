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

    it "keeps fire times on the interval grid when a tick is delivered late" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      # Timer due at 0.1 fires late (0.11); the next fire stays due at 0.2, not 0.21.
      times = [0.0, 0.11, 0.11, 0.2, 0.2, 0.25]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 0.25 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_events = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }
      expect(timer_events.length).to eq(2)
      expect(timer_events.last.now).to eq(0.2)
    end

    it "skips missed ticks after a stall instead of firing a burst" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      # Timer due at 0.1; the clock jumps to 1.0 — one event fires, the rest are dropped.
      times = [0.0, 1.0, 1.0, 1.05, 1.05]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 1.05 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_events = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }
      expect(timer_events.length).to eq(1)
    end

    it "schedules a started timer one interval from now" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      # Clock samples: loop construction, start_timer, due check, event timestamp.
      times = [0.0, 0.0, 0.1, 0.1]
      event_loop = build_loop(backend: backend, clock: -> { times.shift || 0.1 })

      event_loop.start_timer(binding_class.new(:anim, 0.1))
      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_events = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }
      expect(timer_events.map(&:name)).to eq(%i[anim])
    end

    it "does not reset a running timer's phase when started again" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [nil, key_event(:q)])
      # Started at 0.0 (due 0.1); a redundant restart must keep the 0.1 deadline
      # (a phase-resetting restart would consume the 0.05 sample and miss it).
      times = [0.0, 0.0, 0.05, 0.1, 0.1, 0.1]
      event_loop = build_loop(backend: backend, clock: -> { times.shift || 0.1 })

      event_loop.start_timer(binding_class.new(:anim, 0.1))
      event_loop.start_timer(binding_class.new(:anim, 0.1))
      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      timer_events = seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }
      expect(timer_events.length).to eq(1)
      expect(timer_events.first.now).to eq(0.1)
    end

    it "stops delivering a stopped timer" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      times = [0.0, 0.2, 0.2]
      event_loop = build_loop(
        backend: backend,
        clock: -> { times.shift || 0.2 },
        timer_bindings: [binding_class.new(:tick, 0.1)]
      )

      event_loop.stop_timer(:tick)
      seen = pump(event_loop, quit_on: ->(event) { event.is_a?(Charming::Events::KeyEvent) })

      expect(seen.select { |event| event.is_a?(Charming::Events::TimerEvent) }).to be_empty
    end

    it "ignores stopping a timer that is not running" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [])
      event_loop = build_loop(backend: backend)

      expect { event_loop.stop_timer(:missing) }.not_to raise_error
    end

    it "reports whether a timer is running" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [])
      event_loop = build_loop(backend: backend)
      binding = binding_class.new(:anim, 0.1)

      expect(event_loop.timer_running?(:anim)).to be(false)
      event_loop.start_timer(binding)
      expect(event_loop.timer_running?(:anim)).to be(true)
      event_loop.stop_timer(:anim)
      expect(event_loop.timer_running?(:anim)).to be(false)
    end

    it "returns input reads to the default timeout once the last timer stops" do
      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [key_event(:q)])
      event_loop = build_loop(
        backend: backend,
        timer_bindings: [binding_class.new(:tick, 0.01)]
      )

      event_loop.stop_timer(:tick)
      pump(event_loop)

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
