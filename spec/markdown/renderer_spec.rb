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

  describe "definition lists" do
    it "renders terms with indented descriptions" do
      output = render_markdown(<<~MARKDOWN, style: :notty)
        Term
        : The definition of the term.
      MARKDOWN

      expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
        Term
            The definition of the term.
      TEXT
    end

    it "styles the term bold in the dark style" do
      output = render_markdown("Term\n: Details.", style: :dark, width: 40)

      expect(output).to match(/\e\[1[;m]/) # bold SGR, possibly combined with a color
      expect(strip_ansi(output)).to include("Term\n    Details.")
    end

    it "wraps descriptions inside the reduced width" do
      output = render_markdown("Term\n: #{"word " * 12}", style: :notty, width: 30)
      description_lines = strip_ansi(output).lines.drop(1)

      expect(description_lines.length).to be > 1
      description_lines.each do |line|
        expect(line).to start_with("    ")
        expect(Charming::UI::Width.measure(line.chomp)).to be <= 30
      end
    end
  end

  describe "footnotes" do
    it "renders references inline and definitions as labeled blocks" do
      output = render_markdown(<<~MARKDOWN, style: :notty)
        A claim with a footnote[^src] attached.

        [^src]: The footnote body text.
      MARKDOWN

      expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
        A claim with a footnote[src] attached.

        [src]: The footnote body text.
      TEXT
    end

    it "hangs multi-line definitions under the label" do
      output = render_markdown(<<~MARKDOWN, style: :notty, width: 30)
        Note[^a].

        [^a]: #{"word " * 10}
      MARKDOWN

      lines = strip_ansi(output).lines.map(&:chomp)
      definition_start = lines.index { |line| line.start_with?("[a]: ") }
      continuation = lines[(definition_start + 1)..].reject(&:empty?)

      expect(definition_start).not_to be_nil
      continuation.each { |line| expect(line).to start_with(" " * "[a]: ".length) }
    end
  end

  describe "task list checked detection" do
    it "does not check a task whose text merely mentions [x]" do
      output = render_markdown(<<~MARKDOWN, style: :notty)
        - [ ] fix the [x] handling
        - [x] genuinely done
      MARKDOWN

      lines = strip_ansi(output).lines.map(&:chomp)
      expect(lines[0]).to start_with("[ ] ")
      expect(lines[1]).to start_with("[x] ")
    end
  end

  describe "OSC 8 hyperlinks" do
    it "is off by default" do
      output = render_markdown("[Docs](https://example.com)", style: :notty)

      expect(output).not_to include("\e]8")
      expect(strip_ansi(output)).to eq("Docs <https://example.com>")
    end

    it "wraps links in OSC 8 escapes and drops the url suffix when enabled" do
      output = render_markdown("[Docs](https://example.com)", style: :notty, hyperlinks: true)

      expect(output).to include("\e]8;;https://example.com\e\\")
      expect(output).to end_with("\e]8;;\e\\")
      expect(strip_ansi(output)).to eq("Docs")
      expect(Charming::UI::Width.measure(output)).to eq(4)
    end

    it "is exposed through the Markdown component" do
      component = Charming::Components::Markdown.new(
        content: "[Docs](https://example.com)", style: :notty, hyperlinks: true
      )

      expect(component.render).to include("\e]8;;https://example.com\e\\")
    end
  end
end
