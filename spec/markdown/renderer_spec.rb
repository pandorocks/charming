# frozen_string_literal: true

RSpec.describe Charming::Markdown::Renderer do
  def render_markdown(content, **options)
    described_class.new(content: content, **options).render
  end

  def strip_ansi(value)
    Charming::UI::Width.strip_ansi(value)
  end

  it "renders CommonMark blocks with the Glamour-inspired dark style" do
    output = render_markdown(<<~MARKDOWN, width: 40, syntax_highlighting: false)
      # Title

      Hello **Ruby** and `terminals`.

      - One
      - Two

      > Quoted text

      ---
    MARKDOWN

    expect(strip_ansi(output)).to eq([
      " Title ",
      "",
      "Hello Ruby and  terminals .",
      "",
      "• One",
      "• Two",
      "",
      "│ Quoted text",
      "",
      "",
      "  #{"─" * 36}",
      ""
    ].join("\n"))
  end

  it "wraps paragraphs to the requested width" do
    output = render_markdown("Alpha beta gamma", width: 10)

    expect(strip_ansi(output)).to eq("Alpha beta\ngamma")
  end

  it "renders links with resolved destinations" do
    output = render_markdown("Read [docs](/docs).", base_url: "https://example.com/app/")

    expect(strip_ansi(output)).to eq("Read docs <https://example.com/docs>.")
  end

  it "renders markdown entities as text" do
    output = render_markdown("Tom &amp; Jerry")

    expect(strip_ansi(output)).to eq("Tom & Jerry")
  end

  it "renders thematic breaks as inset section separators" do
    output = render_markdown(<<~MARKDOWN, width: 20)
      Before

      ---

      After
    MARKDOWN

    expect(strip_ansi(output)).to eq([
      "Before",
      "",
      "",
      "  #{"─" * 16}",
      "",
      "",
      "After"
    ].join("\n"))
  end

  it "renders notty thematic breaks with ASCII fill" do
    output = render_markdown("---", width: 10, style: :notty)

    expect(strip_ansi(output)).to eq("\n  ------")
  end

  it "syntax highlights fenced code blocks with Rouge" do
    output = render_markdown(<<~MARKDOWN)
      ```ruby
      puts :hi
      ```
    MARKDOWN

    expect(strip_ansi(output)).to include("  puts :hi")
    expect(output).to include("\e[")
  end

  it "preserves newlines between highlighted Ruby tokens" do
    output = render_markdown(<<~MARKDOWN)
      ```ruby
      def hello
        puts "World"
      end
      ```
    MARKDOWN

    expect(strip_ansi(output)).to include("  def hello\n    puts \"World\"\n  end")
  end

  it "can render code blocks without syntax highlighting" do
    output = render_markdown(<<~MARKDOWN, syntax_highlighting: false)
      ```ruby
      puts :hi
      ```
    MARKDOWN

    expect(strip_ansi(output)).to include("  puts :hi")
  end

  it "renders GFM tables" do
    output = render_markdown(<<~MARKDOWN)
      | Name | Value |
      | ---- | ----- |
      | One  | 1     |
      | Two  | 2     |
    MARKDOWN

    expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
      | Name | Value |
      |------|-------|
      | One  | 1     |
      | Two  | 2     |
    TEXT
  end

  it "renders GFM task lists and strikethrough" do
    output = render_markdown(<<~MARKDOWN)
      - [x] Finished
      - [ ] Outstanding

      ~~removed~~
    MARKDOWN

    expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
      [✓] Finished
      [ ] Outstanding

      removed
    TEXT
  end

  it "renders images as terminal-friendly text" do
    output = render_markdown("![Diagram](images/diagram.png)", base_url: "https://example.com/docs/")

    expect(strip_ansi(output)).to eq("Image: Diagram -> https://example.com/docs/images/diagram.png")
  end

  it "supports notty style for plain terminal output" do
    output = render_markdown("# Title\n\n**strong** and *emph*", style: :notty)

    expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
      # Title

      **strong** and *emph*
    TEXT
  end
end
