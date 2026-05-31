# frozen_string_literal: true

require "rouge"

module Charming
  module Presentation
    module Markdown
      class SyntaxHighlighter
        def initialize(theme: UI::Theme.default)
          @theme = theme || UI::Theme.default
        end

        def render(code, language: nil)
          lexer = lexer_for(language, code)
          lexer.lex(code.to_s).map do |token, value|
            style_for(token).render(value)
          end.join
        end

        private

        attr_reader :theme

        def lexer_for(language, code)
          Rouge::Lexer.find_fancy(language, code) || Rouge::Lexers::PlainText
        end

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

        def token_name(token)
          return token.qualname if token.respond_to?(:qualname)

          token.to_s
        end

        def theme_style(name, fallback: nil)
          return theme.public_send(name) if theme.respond_to?(name)

          fallback || UI.style
        end
      end
    end
  end
end
