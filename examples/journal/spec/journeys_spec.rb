# frozen_string_literal: true

require_relative "spec_helper"
require "charming/test_helper"

# Full end-to-end journeys: a real Runtime driving the whole app through a
# MemoryBackend, exactly as a user at a keyboard would.
RSpec.describe "Journal journeys" do
  include Charming::TestHelper

  before do
    session_file = File.expand_path("../tmp/session.json", __dir__)
    File.delete(session_file) if File.exist?(session_file)
    Journal::Entry.create!(title: "Existing entry", mood: "good", body: "Some **bold** text.")
  end

  def run_journey(*keys, width: 100, height: 30)
    backend = memory_backend(*keys, width: width, height: height)
    Charming::Runtime.new(Journal::Application.new, backend: backend,
      task_executor: Charming::Tasks::InlineExecutor).run
    backend
  end

  def plain(frame)
    Charming::UI::Width.strip_ansi(frame.to_s)
  end

  it "boots into the entry list with the status bar" do
    backend = run_journey("q")
    frame = plain(backend.frames.first)

    expect(frame).to include("✦ Journal")
    expect(frame).to include("Existing entry")
    expect(frame).to include("enter open")
    expect(frame).to include("1 entries")
  end

  it "opens an entry and renders its markdown" do
    backend = run_journey("enter", "q")
    frame = plain(backend.frames.last)

    expect(frame).to include("Journal › Existing entry")
    expect(frame).to include("Some")
  end

  it "creates an entry end-to-end through the compose form" do
    keys = ["n", *"Demo day".chars, "enter", "down", "enter", *"It worked.".chars, "ctrl+s", "q"]
    backend = run_journey(*keys)

    entry = Journal::Entry.find_by(title: "Demo day")
    expect(entry).not_to be_nil
    expect(entry.mood).to eq("meh")
    expect(entry.body).to eq("It worked.")
    expect(plain(backend.frames.last)).to include("Journal › Demo day")
  end

  it "types ? and q into the body instead of triggering shortcuts" do
    keys = [
      "n", *"Questions".chars, "tab", "tab",        # title, then tab to mood, tab to body
      *"why? q?".chars,
      "ctrl+s", "q"
    ]
    run_journey(*keys)

    entry = Journal::Entry.find_by(title: "Questions")
    expect(entry).not_to be_nil
    expect(entry.body).to eq("why? q?")
  end

  it "moves between form fields with tab instead of bouncing to the sidebar" do
    keys = ["n", *"Tab test".chars, "tab", "down", "tab", *"body".chars, "ctrl+s", "q"]
    run_journey(*keys)

    entry = Journal::Entry.find_by(title: "Tab test")
    expect(entry).not_to be_nil
    expect(entry.mood).to eq("meh")
    expect(entry.body).to eq("body")
  end

  it "writes multi-paragraph bodies — enter makes new lines, twice for a blank line" do
    keys = [
      "n", *"Two paragraphs".chars, "enter", "enter", # title, advance past mood
      *"First.".chars, "enter", "enter", *"Second.".chars,
      "ctrl+s", "q"
    ]
    run_journey(*keys)

    entry = Journal::Entry.find_by(title: "Two paragraphs")
    expect(entry.body).to eq("First.\n\nSecond.")
  end

  it "shows a toast after toggling favorite" do
    backend = run_journey("f", "q")
    expect(plain(backend.frames.last)).to include("favorites")
  end

  it "deletes through the confirm modal" do
    backend = run_journey("d", "y", "q")

    expect(Journal::Entry.count).to eq(0)
    expect(plain(backend.frames.last)).to include("No entries yet")
  end

  it "captures keys inside the help overlay" do
    backend = run_journey("?", "n", "q")

    expect(backend.frames.any? { |f| plain(f).include?("Keyboard Shortcuts") }).to be true
    expect(backend.frames.none? { |f| plain(f).include?("What happened today?") }).to be true
  end

  it "navigates the sidebar to stats and exports" do
    backend = run_journey("tab", "j", "j", "enter", "x", "q")
    frames = backend.frames.map { |f| plain(f) }

    expect(frames.any? { |f| f.include?("Writing stats") }).to be true
    expect(frames.any? { |f| f.include?("Exported 1 entries") }).to be true
  end

  it "opens the command palette and quits through it" do
    backend = run_journey("ctrl+p", *"quit".chars, "enter")
    expect(backend.frames.any? { |f| plain(f).include?("Search commands") }).to be true
  end
end
