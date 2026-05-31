# frozen_string_literal: true

require "timeout"

RSpec.describe Charming::Tasks do
  def pop_with_timeout(queue)
    Timeout.timeout(1) { queue.pop }
  end

  describe Charming::Tasks::InlineExecutor do
    it "enqueues successful task results synchronously" do
      queue = Thread::Queue.new
      executor = described_class.new(queue)

      result = executor.submit(:fetch) { "feed" }

      expect(result).to be_nil
      event = queue.pop(true)
      expect(event).to eq(Charming::Events::TaskEvent.new(name: :fetch, value: "feed"))
    end

    it "captures task errors synchronously" do
      queue = Thread::Queue.new
      executor = described_class.new(queue)

      executor.submit(:fetch) { raise "boom" }

      event = queue.pop(true)
      expect(event).to be_error
      expect(event.error.message).to eq("boom")
    end
  end

  describe Charming::Tasks::ThreadedExecutor do
    it "returns nil and enqueues successful task results" do
      queue = Thread::Queue.new
      executor = described_class.new(queue)

      result = executor.submit(:fetch) { "feed" }

      expect(result).to be_nil
      expect(pop_with_timeout(queue)).to eq(Charming::Events::TaskEvent.new(name: :fetch, value: "feed"))
    ensure
      executor&.shutdown
    end

    it "captures task errors" do
      queue = Thread::Queue.new
      executor = described_class.new(queue)

      executor.submit(:fetch) { raise "boom" }

      event = pop_with_timeout(queue)
      expect(event).to be_error
      expect(event.error.message).to eq("boom")
    ensure
      executor&.shutdown
    end

    it "kills running tasks during shutdown" do
      queue = Thread::Queue.new
      started = Thread::Queue.new
      executor = described_class.new(queue)

      executor.submit(:slow) do
        started << true
        sleep 10
      end
      started.pop

      executor.shutdown(timeout: 0.01)

      threads = executor.instance_variable_get(:@threads)
      Timeout.timeout(1) { Thread.pass while threads.any?(&:alive?) }
      expect(threads).to all(satisfy { |thread| !thread.alive? })
    end
  end
end
