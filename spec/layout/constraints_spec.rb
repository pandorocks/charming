# frozen_string_literal: true

RSpec.describe "Layout pane constraints" do
  let(:view) { Charming::View.new }
  let(:screen) { Charming::Screen.new(width: 100, height: 20) }

  def build_layout(&)
    Charming::Layout::Builder.build(screen: screen, view: view, &)
  end

  describe "min_width" do
    it "keeps a grow pane at or above its minimum" do
      layout = build_layout do
        split(:horizontal) do
          pane(:sidebar, width: 90) { "side" }
          pane(:content, grow: 1, min_width: 30) { "main" }
        end
      end

      targets = layout.mouse_targets
      content = targets.find { |t| t[:name] == :content }
      expect(content[:rect].width).to eq(30)
    end
  end

  describe "max_width" do
    it "caps a grow pane at its maximum and gives back the surplus" do
      layout = build_layout do
        split(:horizontal) do
          pane(:sidebar, grow: 1, max_width: 20) { "side" }
          pane(:content, grow: 1) { "main" }
        end
      end

      targets = layout.mouse_targets
      sidebar = targets.find { |t| t[:name] == :sidebar }
      content = targets.find { |t| t[:name] == :content }
      expect(sidebar[:rect].width).to eq(20)
      expect(content[:rect].width).to eq(80)
    end
  end

  describe "min_height in vertical splits" do
    it "enforces a minimum row count" do
      layout = build_layout do
        split(:vertical) do
          pane(:header, height: 18) { "head" }
          pane(:footer, grow: 1, min_height: 5) { "foot" }
        end
      end

      footer = layout.mouse_targets.find { |t| t[:name] == :footer }
      expect(footer[:rect].height).to eq(5)
    end
  end

  it "leaves unconstrained layouts untouched" do
    layout = build_layout do
      split(:horizontal) do
        pane(:a, width: 30) { "a" }
        pane(:b, grow: 1) { "b" }
      end
    end

    b = layout.mouse_targets.find { |t| t[:name] == :b }
    expect(b[:rect].width).to eq(70)
  end
end

RSpec.describe "Overlay z-order" do
  let(:view) { Charming::View.new }
  let(:screen) { Charming::Screen.new(width: 11, height: 1) }

  it "composites higher z_index overlays on top regardless of registration order" do
    layout = Charming::Layout::Builder.build(screen: screen, view: view) do
      pane(:base) { "..........." }
      overlay("TOP", top: 0, left: 0, z_index: 10)
      overlay("UNDERNEATH", top: 0, left: 0, z_index: 1)
    end

    frame = layout.render
    # "TOP" must paint over "UNDERNEATH": result starts with TOP + remaining of UNDERNEATH
    expect(frame).to start_with("TOPERNEATH")
  end

  it "keeps registration order for equal z_index" do
    layout = Charming::Layout::Builder.build(screen: screen, view: view) do
      pane(:base) { "..........." }
      overlay("first", top: 0, left: 0)
      overlay("SECOND", top: 0, left: 0)
    end

    expect(layout.render).to start_with("SECOND")
  end
end
