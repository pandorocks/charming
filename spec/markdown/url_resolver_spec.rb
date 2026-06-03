# frozen_string_literal: true

RSpec.describe Charming::Markdown::URLResolver do
  it "returns the value when no base URL is configured" do
    resolver = described_class.new(base_url: nil)

    expect(resolver.resolve("/docs")).to eq("/docs")
  end

  it "returns empty values unchanged" do
    resolver = described_class.new(base_url: "https://example.com/app/")

    expect(resolver.resolve("")).to eq("")
  end

  it "returns absolute URLs unchanged" do
    resolver = described_class.new(base_url: "https://example.com/app/")

    expect(resolver.resolve("https://ruby-lang.org")).to eq("https://ruby-lang.org")
  end

  it "resolves relative URLs against the base URL" do
    resolver = described_class.new(base_url: "https://example.com/app/")

    expect(resolver.resolve("guides/start")).to eq("https://example.com/app/guides/start")
  end

  it "returns invalid URLs unchanged" do
    resolver = described_class.new(base_url: "https://example.com/app/")

    expect(resolver.resolve("http://[invalid")).to eq("http://[invalid")
  end
end
