# frozen_string_literal: true

RSpec.describe Charming::Focus do
  let(:session) { {} }
  let(:controller_class) { Class.new { def self.name = "FocusSpecController" } }

  def focus_for(slots = [])
    described_class.for(session, controller_class).tap do |f|
      f.define(slots) unless slots.empty?
    end
  end

  it "exposes the ring's first slot as the initial current focus" do
    expect(focus_for(%i[a b c]).current).to eq(:a)
  end

  it "is idempotent across controller re-instantiations" do
    focus_for(%i[a b])
    focus_for(%i[a b])

    expect(session[:focus_state]["FocusSpecController"][:scopes].length).to eq(1)
  end

  it "persists current focus across controller re-instantiations" do
    focus_for(%i[a b]).focus(:b)

    expect(focus_for(%i[a b]).current).to eq(:b)
  end

  it "cycles forward and wraps from last to first" do
    focus = focus_for(%i[a b c])

    focus.cycle(+1)
    focus.cycle(+1)
    expect(focus.current).to eq(:c)

    focus.cycle(+1)
    expect(focus.current).to eq(:a)
  end

  it "cycles backward and wraps from first to last" do
    focus = focus_for(%i[a b c])

    focus.cycle(-1)

    expect(focus.current).to eq(:c)
  end

  it "ignores focus(:slot) when the slot is not in the current ring" do
    focus = focus_for(%i[a b])

    focus.focus(:not_a_slot)

    expect(focus.current).to eq(:a)
  end

  describe "scope stack" do
    it "directs current/ring to the topmost scope while it is pushed" do
      focus = focus_for(%i[a b])
      focus.push_scope(%i[palette])

      expect(focus.current).to eq(:palette)
      expect(focus.ring).to eq(%i[palette])
    end

    it "restores the underlying ring's current after pop_scope" do
      focus = focus_for(%i[a b])
      focus.focus(:b)
      focus.push_scope(%i[palette])
      focus.pop_scope

      expect(focus.current).to eq(:b)
    end

    it "cycles only within the topmost scope" do
      focus = focus_for(%i[a b])
      focus.push_scope(%i[x y z])

      focus.cycle(+1)

      expect(focus.current).to eq(:y)
    end
  end

  describe "#focused?" do
    it "returns true for the current slot and false for others" do
      focus = focus_for(%i[a b])

      expect(focus.focused?(:a)).to be(true)
      expect(focus.focused?(:b)).to be(false)
    end
  end
end
