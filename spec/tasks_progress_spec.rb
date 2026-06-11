# frozen_string_literal: true

RSpec.describe "Task progress and cancellation" do
  let(:queue) { Thread::Queue.new }

  def drain(queue)
    events = []
    events << queue.pop(true) until queue.empty?
    events
  rescue ThreadError
    events
  end

  describe "progress reporting" do
    it "delivers progress events before the completion event (inline)" do
      executor = Charming::Tasks::InlineExecutor.new(queue)
      executor.submit(:import) do |progress|
        progress.report(1, of: 2, message: "halfway")
        progress.report(2, of: 2)
        :done
      end

      events = drain(queue)
      expect(events.length).to eq(3)
      expect(events[0]).to be_a(Charming::Events::TaskProgressEvent)
      expect(events[0].current).to eq(1)
      expect(events[0].total).to eq(2)
      expect(events[0].message).to eq("halfway")
      expect(events[0].fraction).to eq(0.5)
      expect(events[2]).to be_a(Charming::Events::TaskEvent)
      expect(events[2].value).to eq(:done)
    end

    it "delivers progress events from threaded tasks" do
      executor = Charming::Tasks::ThreadedExecutor.new(queue)
      executor.submit(:work) do |progress|
        progress.report(1, of: 1)
        :ok
      end
      executor.shutdown(timeout: 2.0)

      events = drain(queue)
      expect(events.first).to be_a(Charming::Events::TaskProgressEvent)
      expect(events.last.value).to eq(:ok)
    end

    it "still supports zero-arity blocks" do
      executor = Charming::Tasks::InlineExecutor.new(queue)
      executor.submit(:simple) { 42 }
      expect(drain(queue).first.value).to eq(42)
    end
  end

  describe "timeout" do
    it "cancels a task that exceeds its timeout" do
      executor = Charming::Tasks::ThreadedExecutor.new(queue)
      executor.submit(:slow, timeout: 0.05) { sleep 5 }
      executor.shutdown(timeout: 2.0)

      event = drain(queue).last
      expect(event.error).to be_a(Charming::Tasks::Cancelled)
      expect(event.error.message).to include("timed out")
    end
  end

  describe "cancellation" do
    it "cancels a named in-flight task" do
      executor = Charming::Tasks::ThreadedExecutor.new(queue)
      started = Thread::Queue.new
      executor.submit(:long) do
        started << true
        sleep 5
      end
      started.pop # ensure the task is running
      executor.cancel(:long)
      executor.shutdown(timeout: 2.0)

      event = drain(queue).last
      expect(event.error).to be_a(Charming::Tasks::Cancelled)
    end

    it "is a no-op for unknown task names" do
      executor = Charming::Tasks::ThreadedExecutor.new(queue)
      expect { executor.cancel(:missing) }.not_to raise_error
    end
  end

  describe "controller integration" do
    it "dispatches on_task_progress handlers through the runtime" do
      controller_class = Class.new(Charming::Controller) do
        key "s", :start
        key "q", :quit

        on_task :import, action: :import_done
        on_task_progress :import, action: :import_progress

        def show
          render "progress: #{session.fetch(:progress, "none")} done: #{session.fetch(:done, false)}"
        end

        def start
          run_task(:import) do |progress|
            progress.report(3, of: 10, message: "rows")
            :finished
          end
          show
        end

        def import_progress
          session[:progress] = "#{event.current}/#{event.total} #{event.message}"
          show
        end

        def import_done
          session[:done] = event.value
          show
        end
      end
      stub_const("ProgressSpecController", controller_class)
      app_class = Class.new(Charming::Application)
      stub_const("ProgressSpecApp", app_class)
      app_class.routes do
        root "progress_spec#show"
      end

      backend = Charming::Internal::Terminal::MemoryBackend.new(events: [
        Charming::Events::KeyEvent.new(key: :s),
        Charming::Events::KeyEvent.new(key: :q)
      ])
      Charming::Runtime.new(ProgressSpecApp.new, backend: backend, task_executor: Charming::Tasks::InlineExecutor).run

      final = backend.frames.last
      expect(final).to include("progress: 3/10 rows")
      expect(final).to include("done: finished")
    end
  end
end
