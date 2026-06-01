# frozen_string_literal: true

require "kramdown"

RSpec.describe Charming::Presentation::Markdown::BlockRenderer do
  let(:renderer) { Charming::Presentation::Markdown::Renderer.new(content: "", width: 40) }
  let(:subject_instance) { described_class.new(renderer: renderer) }

  def context(width: 40)
    Charming::Presentation::Markdown::RenderContext.from(width: width)
  end

  def first_block(markdown)
    doc = Kramdown::Document.new(markdown)
    doc.root.children.find { |c| c.type != :blank } || doc.root.children.first
  end

  def strip_ansi(value)
    Charming::Presentation::UI::Width.strip_ansi(value.to_s)
  end

  describe "paragraphs" do
    it "wraps inline children to the context width" do
      para = first_block("alpha beta gamma")

      result = subject_instance.render(para, context: context(width: 10))

      expect(strip_ansi(result)).to eq("alpha beta\ngamma")
    end
  end

  describe "headers" do
    it "renders h1 with the title style (no ANSI after stripping)" do
      h1 = first_block("# Title")

      result = subject_instance.render(h1, context: context)

      expect(strip_ansi(result)).to eq("Title")
    end

    it "renders h2 with the subheading style" do
      h2 = first_block("## Sub")

      result = subject_instance.render(h2, context: context)

      expect(strip_ansi(result)).to eq("Sub")
    end
  end

  describe "blockquotes" do
    it "renders with a left border and indented body" do
      bq = first_block("> hello\n> world")

      result = subject_instance.render(bq, context: context)

      expect(strip_ansi(result)).to eq("| hello\n| world")
    end
  end

  describe "unordered lists" do
    it "renders items with a dash marker" do
      ul = first_block("- one\n- two")

      result = subject_instance.render(ul, context: context)

      expect(strip_ansi(result)).to eq("- one\n- two")
    end
  end

  describe "ordered lists" do
    it "renders items with numeric markers starting at 1" do
      ol = first_block("1. one\n2. two")

      result = subject_instance.render(ol, context: context)

      expect(strip_ansi(result)).to eq("1. one\n2. two")
    end
  end

  describe "list items" do
    it "renders item body under the marker with continuation indent" do
      li_doc = Kramdown::Document.new("- one\n  two")
      li = li_doc.root.children.first.children.first

      result = subject_instance.render(li, context: context)

      # "one" is the first line; "two" continues under it
      expect(strip_ansi(result)).to include("two")
    end
  end

  describe "code blocks" do
    it "renders fenced code with syntax highlighting (colored output)" do
      cb = first_block("~~~ ruby\nputs :hi\n~~~")

      result = subject_instance.render(cb, context: context)

      expect(strip_ansi(result)).to eq("  puts :hi")
      expect(result).to include("\e[")
    end

    it "renders fenced code without syntax highlighting when disabled" do
      no_highlight = Charming::Presentation::Markdown::Renderer
        .new(content: "~~~ ruby\nputs :hi\n~~~", width: 40, syntax_highlighting: false)
      block_renderer = described_class.new(renderer: no_highlight)
      cb = first_block("~~~ ruby\nputs :hi\n~~~")

      result = block_renderer.render(cb, context: context)

      # Without highlighting, the code is rendered as a single colored block (the
      # warn style) — one start sequence, not a per-token color per character.
      expect(strip_ansi(result)).to eq("  puts :hi")
      start_count = result.scan("\e[").length
      expect(start_count).to be < 3
    end
  end

  describe "horizontal rules" do
    it "renders an hr as a row of dashes" do
      hr = first_block("---")

      result = subject_instance.render(hr, context: context)

      expect(strip_ansi(result)).to eq("-" * 40)
    end
  end

  describe "blank elements" do
    it "returns nil so the filter_map drops them" do
      doc = Kramdown::Document.new("\n")
      blank = doc.root.children.find { |c| c.type == :blank }

      expect(subject_instance.render(blank, context: context)).to be_nil
    end
  end

  describe "unknown element types" do
    it "falls back to plain text for leaf unknowns" do
      fake_element = Struct.new(:type, :value, :children).new(:unknown, "raw text", [])

      result = subject_instance.send(:render_unknown, fake_element, context)

      expect(strip_ansi(result)).to eq("raw text")
    end

    it "recurses into children for unknown element types with children" do
      child = first_block("alpha beta gamma")
      fake_element = Struct.new(:type, :value, :children).new(:unknown, "", [child])

      result = subject_instance.send(:render_unknown, fake_element, context(width: 10))

      expect(strip_ansi(result)).to eq("alpha beta\ngamma")
    end
  end
end
