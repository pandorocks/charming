# frozen_string_literal: true

RSpec.describe "Built-in themes and inheritance" do
  describe "bundled themes" do
    it "ships the expected built-in themes" do
      names = Charming::UI::Theme.built_in_names
      expect(names).to include("phosphor", "catppuccin-mocha", "catppuccin-latte", "gruvbox-dark", "nord", "tokyonight")
    end

    Charming::UI::Theme.built_in_names.each do |name|
      it "loads #{name} with all framework style tokens" do
        theme = Charming::UI::Theme.load_builtin(name)
        %i[text muted title selected header header_accent sidebar main footer modal border info warn].each do |token|
          expect(theme.style(token)).to be_a(Charming::UI::Style)
        end
        expect(theme.background).not_to be_nil
      end
    end
  end

  describe "theme inheritance" do
    it "derives a theme with overrides via extends:" do
      app_class = Class.new(Charming::Application)
      app_class.theme :base, built_in: "nord"
      app_class.theme :loud, extends: :base, overrides: {text: {foreground: "#ffffff", bold: true}}

      base = app_class.theme_for(:base)
      loud = app_class.theme_for(:loud)

      expect(loud.text.render("x")).not_to eq(base.text.render("x"))
      expect(loud.text.render("x")).to include("255;255;255")
      # untouched tokens are inherited
      expect(loud.muted.render("x")).to eq(base.muted.render("x"))
    end

    it "raises for an unknown parent" do
      app_class = Class.new(Charming::Application)
      expect {
        app_class.theme :broken, extends: :missing
      }.to raise_error(ArgumentError, /unknown parent theme/)
    end

    it "raises when overrides are given without extends" do
      app_class = Class.new(Charming::Application)
      expect {
        app_class.theme :broken, built_in: "nord", overrides: {}
      }.to raise_error(ArgumentError, /overrides: requires extends:/)
    end

    it "raises when multiple sources are given" do
      app_class = Class.new(Charming::Application)
      expect {
        app_class.theme :broken, built_in: "nord", extends: :other
      }.to raise_error(ArgumentError, /only one of/)
    end
  end
end
