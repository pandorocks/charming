# frozen_string_literal: true

require "kramdown"

RSpec.describe Charming::Markdown::InlineRenderer do
  let(:renderer) { Charming::Markdown::Renderer.new(content: "", width: 40) }
  let(:subject_instance) { described_class.new(renderer: renderer) }
  let(:context) { Charming::Markdown::RenderContext.from(width: 40) }

  def first_inline(markdown)
    Kramdown::Document.new(markdown).root.children.first.children.first
  end

  def strip_ansi(value)
    Charming::UI::Width.strip_ansi(value.to_s)
  end

  describe "text elements" do
    it "renders verbatim" do
      text = first_inline("hello world")

      result = subject_instance.render(text, context: context)

      expect(strip_ansi(result)).to eq("hello world")
    end
  end

  describe "strong elements" do
    it "renders with the strong style (or bold text fallback)" do
      strong = first_inline("**bold**")

      result = subject_instance.render(strong, context: context)

      expect(strip_ansi(result)).to eq("bold")
    end
  end

  describe "em elements" do
    it "renders with the emphasis style (or italic text fallback)" do
      em = first_inline("*slant*")

      result = subject_instance.render(em, context: context)

      expect(strip_ansi(result)).to eq("slant")
    end
  end

  describe "codespan elements" do
    it "renders the raw code value" do
      cs = first_inline("`code`")

      result = subject_instance.render(cs, context: context)

      expect(strip_ansi(result)).to eq("code")
    end
  end

  describe "link elements" do
    it "renders the label and href with angle brackets" do
      link = first_inline("[docs](https://example.com/docs)")

      result = subject_instance.render(link, context: context)

      expect(strip_ansi(result)).to eq("docs <https://example.com/docs>")
    end
  end

  describe "br elements" do
    it "renders a newline" do
      # Kramdown treats "\n" inside paragraph as text — the :br case is defensive
      # (a backslash-break or other parser) and we exercise the handler directly.
      fake = Struct.new(:type, :value, :children, :attr, :options).new(:br, "", [], {}, {})

      result = subject_instance.render(fake, context: context)

      expect(result).to eq("\n")
    end
  end

  describe "entity elements" do
    it "renders via #char when the entity supports it" do
      amp = Kramdown::Document.new("Tom &amp; Jerry").root.children.first.children.find { |c| c.type == :entity }

      result = subject_instance.render(amp, context: context)

      expect(result).to eq("&")
    end

    it "falls back to to_s when the entity has no #char" do
      fake = Struct.new(:type, :value, :children, :attr, :options)
        .new(:entity, "raw_entity_value", [], {}, {})

      result = subject_instance.render(fake, context: context)

      expect(result).to eq("raw_entity_value")
    end
  end

  describe "unknown inline types" do
    it "falls back to element.value.to_s for leaf unknowns" do
      fake = Struct.new(:type, :value, :children, :attr, :options)
        .new(:unknown, "raw", [], {}, {})

      result = subject_instance.render(fake, context: context)

      expect(strip_ansi(result)).to eq("raw")
    end

    it "recurses into children for unknown inline types with children" do
      child = first_inline("nested")
      fake = Struct.new(:type, :value, :children, :attr, :options)
        .new(:unknown, "", [child], {}, {})

      result = subject_instance.render(fake, context: context)

      expect(strip_ansi(result)).to eq("nested")
    end
  end
end
