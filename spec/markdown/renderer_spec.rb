# frozen_string_literal: true

RSpec.describe Charming::Markdown::Renderer do
  def render_markdown(content, **options)
    described_class.new(content: content, **options).render
  end

  def strip_ansi(value)
    Charming::UI::Width.strip_ansi(value)
  end

  it "renders common block elements through Kramdown" do
    output = render_markdown(<<~MARKDOWN, width: 40)
      # Title

      Hello **Ruby** and `terminals`.

      - One
      - Two

      > Quoted text

      ---
    MARKDOWN

    expect(strip_ansi(output)).to eq(<<~TEXT.chomp)
      Title

      Hello Ruby and terminals.

      - One
      - Two

      | Quoted text

      ----------------------------------------
    TEXT
  end

  it "wraps paragraphs to the requested width" do
    output = render_markdown("Alpha beta gamma", width: 10)

    expect(strip_ansi(output)).to eq("Alpha beta\ngamma")
  end

  it "renders links with their destination" do
    output = render_markdown("Read [docs](https://example.com/docs).", width: 80)

    expect(strip_ansi(output)).to eq("Read docs <https://example.com/docs>.")
  end

  it "renders markdown entities as text" do
    output = render_markdown("Tom &amp; Jerry")

    expect(strip_ansi(output)).to eq("Tom & Jerry")
  end

  it "syntax highlights fenced code blocks with Rouge" do
    output = render_markdown(<<~MARKDOWN)
      ~~~ ruby
      puts :hi
      ~~~
    MARKDOWN

    expect(strip_ansi(output)).to eq("  puts :hi")
    expect(output).to include("\e[")
  end

  it "can render code blocks without syntax highlighting" do
    output = render_markdown(<<~MARKDOWN, syntax_highlighting: false)
      ~~~ ruby
      puts :hi
      ~~~
    MARKDOWN

    expect(strip_ansi(output)).to eq("  puts :hi")
  end

  it "falls back to plain text for unknown code languages" do
    output = render_markdown(<<~MARKDOWN)
      ~~~ not-a-language
      hello
      ~~~
    MARKDOWN

    expect(strip_ansi(output)).to eq("  hello")
  end
end
