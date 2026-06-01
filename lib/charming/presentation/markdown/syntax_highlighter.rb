# frozen_string_literal: true

require "rouge"

module Charming
  module Presentation
    module Markdown
      # SyntaxHighlighter turns a code block string into ANSI-styled terminal text using
      # Rouge lexers. The theme provides markdown_code_* tokens for per-token styling;
      # when a token is undefined in the theme, the highlighter falls back to a sensible
      # base style (muted italic for comments, title for keywords, etc.).
      class SyntaxHighlighter
        # *theme* is the active Charming theme. Defaults to UI::Theme.default.
        def initialize(theme: UI::Theme.default)
          @theme = theme || UI::Theme.default
        end

        # Highlights *code* (using Rouge) for the given *language* (auto-detected when nil)
        # and returns a styled multi-line string. Each Rouge token is rendered with the
        # theme style matching its token type.
        def render(code, language: nil)
          lexer = lexer_for(language, code)
          lexer.lex(code.to_s).map do |token, value|
            style_for(token).render(value)
          end.join
        end

        private

        # The Charming theme used for token styling.
        attr_reader :theme

        # Picks a Rouge lexer for *language* and *code*, falling back to plain text.
        def lexer_for(language, code)
          Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
        end

        # Returns the Charming style for a given Rouge *token*, mapping token qualifiers
        # to theme tokens and falling back to a sensible base style per category.
        def style_for(token)
          name = token_name(token)

          case name
          when /Comment/
            theme_style(:markdown_code_comment, fallback: theme_style(:muted).italic)
          when /Keyword/
            theme_style(:markdown_code_keyword, fallback: theme_style(:title))
          when /String/
            theme_style(:markdown_code_string, fallback: theme_style(:warn))
          when /Number|Literal/
            theme_style(:markdown_code_literal, fallback: theme_style(:info))
          when /Name\.(Class|Constant|Function|Namespace)/
            theme_style(:markdown_code_constant, fallback: theme_style(:info))
          when /Error/
            theme_style(:markdown_code_error, fallback: theme_style(:warn).bold)
          else
            theme_style(:markdown_code, fallback: theme_style(:text))
          end
        end

        # Returns the qualified token name when the token object supports it, otherwise
        # the token's default `to_s`.
        def token_name(token)
          return token.qualname if token.respond_to?(:qualname)

          token.to_s
        end

        # Returns the theme's style for *name*, falling back to *fallback* (or a default
        # empty style) when the theme doesn't define it.
        def theme_style(name, fallback: nil)
          return theme.public_send(name) if theme.respond_to?(name)

          fallback || UI.style
        end
      end
    end
  end
end
