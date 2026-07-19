# frozen_string_literal: true

RSpec.describe Charming::Internal::TimerControl do
  let(:binding) { Charming::Controller::TimerBinding.new(name: :slide, interval: 0.1, action: :step, autostart: false) }
  let(:event_loop) do
    instance_double(Charming::Internal::EventLoop, start_timer: nil, stop_timer: nil, timer_running?: false)
  end
  let(:control) { described_class.new(event_loop: event_loop, bindings: -> { {slide: binding} }) }

  it "starts a declared timer on the event loop" do
    control.start(:slide)

    expect(event_loop).to have_received(:start_timer).with(binding)
  end

  it "raises when starting a timer the controller does not declare" do
    expect { control.start(:missing) }.to raise_error(ArgumentError, /unknown timer :missing/)
  end

  it "stops a timer by name" do
    control.stop(:slide)

    expect(event_loop).to have_received(:stop_timer).with(:slide)
  end

  it "reports whether a timer is running" do
    allow(event_loop).to receive(:timer_running?).with(:slide).and_return(true)

    expect(control.running?(:slide)).to be(true)
  end

  describe described_class::Null do
    it "ignores starts and stops and reports nothing running" do
      null = described_class.new

      expect { null.start(:slide) }.not_to raise_error
      expect { null.stop(:slide) }.not_to raise_error
      expect(null.running?(:slide)).to be(false)
    end
  end
end
