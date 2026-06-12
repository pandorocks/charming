# frozen_string_literal: true

module Charming
  module Markdown
    class StyleConfig
      ELEMENTS = %i[
        document paragraph block_quote list heading h1 h2 h3 h4 h5 h6 text
        strikethrough emph strong hr item enumeration task link link_text image
        image_text code code_block table definition_list definition_term
        definition_description html_block html_span
      ].freeze

      BUILT_INS = {
        notty: {
          block_quote: {indent: 1, indent_token: "| "},
          list: {level_indent: 2},
          h1: {prefix: "# "},
          h2: {prefix: "## "},
          h3: {prefix: "### "},
          h4: {prefix: "#### "},
          h5: {prefix: "##### "},
          h6: {prefix: "###### "},
          emph: {block_prefix: "*", block_suffix: "*"},
          strong: {block_prefix: "**", block_suffix: "**"},
          strikethrough: {block_prefix: "~~", block_suffix: "~~"},
          hr: {format: "-", indent: 2, margin: 1},
          item: {block_prefix: "- "},
          enumeration: {block_prefix: ". "},
          task: {ticked: "[x] ", unticked: "[ ] "},
          code: {block_prefix: "`", block_suffix: "`"},
          code_block: {margin: 1},
          table: {column_separator: "|", row_separator: "-"},
          definition_description: {indent: 4},
          image_text: {format: "Image: {{text}} ->"}
        },
        dark: {
          document: {color: "252"},
          block_quote: {color: "244", indent: 1, indent_token: "│ "},
          list: {level_indent: 2},
          heading: {color: "39", bold: true},
          h1: {prefix: " ", suffix: " ", color: "228", background_color: "63", bold: true},
          h2: {prefix: "## "},
          h3: {prefix: "### "},
          h4: {prefix: "#### "},
          h5: {prefix: "##### "},
          h6: {prefix: "###### ", color: "35", bold: false},
          strikethrough: {crossed_out: true},
          emph: {italic: true},
          strong: {bold: true},
          hr: {color: "240", format: "─", indent: 2, margin: 1},
          item: {block_prefix: "• "},
          enumeration: {block_prefix: ". "},
          task: {ticked: "[✓] ", unticked: "[ ] "},
          link: {color: "30", underline: true},
          link_text: {color: "35", bold: true},
          image: {color: "212", underline: true},
          image_text: {color: "243", format: "Image: {{text}} ->"},
          code: {prefix: " ", suffix: " ", color: "203", background_color: "236"},
          code_block: {color: "244", margin: 1},
          table: {column_separator: "|", row_separator: "-"},
          definition_term: {bold: true},
          definition_description: {indent: 4, color: "244"}
        },
        light: {
          document: {color: "236"},
          block_quote: {color: "244", indent: 1, indent_token: "│ "},
          list: {level_indent: 2},
          heading: {color: "25", bold: true},
          h1: {prefix: " ", suffix: " ", color: "255", background_color: "33", bold: true},
          h2: {prefix: "## "},
          h3: {prefix: "### "},
          h4: {prefix: "#### "},
          h5: {prefix: "##### "},
          h6: {prefix: "###### ", color: "30", bold: false},
          strikethrough: {crossed_out: true},
          emph: {italic: true},
          strong: {bold: true},
          hr: {color: "250", format: "─", indent: 2, margin: 1},
          item: {block_prefix: "• "},
          enumeration: {block_prefix: ". "},
          task: {ticked: "[✓] ", unticked: "[ ] "},
          link: {color: "25", underline: true},
          link_text: {color: "90", bold: true},
          image: {color: "162", underline: true},
          image_text: {color: "244", format: "Image: {{text}} ->"},
          code: {prefix: " ", suffix: " ", color: "161", background_color: "255"},
          code_block: {color: "244", margin: 1},
          table: {column_separator: "|", row_separator: "-"},
          definition_term: {bold: true},
          definition_description: {indent: 4, color: "244"}
        }
      }.freeze

      ATTRIBUTES = %i[bold faint italic underline reverse strikethrough].freeze

      Style = Data.define(
        :block_prefix, :block_suffix, :prefix, :suffix, :color, :background_color,
        :bold, :faint, :italic, :underline, :reverse, :strikethrough, :format,
        :indent, :indent_token, :margin, :level_indent, :ticked, :unticked,
        :column_separator, :row_separator
      ) do
        def self.from(value)
          value = symbolize_keys(value || {})
          new(
            block_prefix: value[:block_prefix].to_s,
            block_suffix: value[:block_suffix].to_s,
            prefix: value[:prefix].to_s,
            suffix: value[:suffix].to_s,
            color: normalize_color(value[:color] || value[:foreground] || value[:fg]),
            background_color: normalize_color(value[:background_color] || value[:background] || value[:bg]),
            bold: value[:bold],
            faint: value[:faint],
            italic: value[:italic],
            underline: value[:underline],
            reverse: value[:reverse] || value[:inverse],
            strikethrough: value[:strikethrough] || value[:crossed_out],
            format: value[:format].to_s,
            indent: value[:indent]&.to_i,
            indent_token: value[:indent_token]&.to_s,
            margin: value[:margin]&.to_i,
            level_indent: value[:level_indent]&.to_i,
            ticked: value[:ticked]&.to_s,
            unticked: value[:unticked]&.to_s,
            column_separator: value[:column_separator]&.to_s,
            row_separator: value[:row_separator]&.to_s
          )
        end

        def inherit_visual(child)
          child = self.class.from(child) unless child.is_a?(self.class)
          self.class.new(**child.to_h.merge(
            color: child.color || color,
            background_color: child.background_color || background_color,
            bold: child.bold.nil? ? bold : child.bold,
            faint: child.faint.nil? ? faint : child.faint,
            italic: child.italic.nil? ? italic : child.italic,
            underline: child.underline.nil? ? underline : child.underline,
            reverse: child.reverse.nil? ? reverse : child.reverse,
            strikethrough: child.strikethrough.nil? ? strikethrough : child.strikethrough
          ))
        end

        def render(value)
          ansi_codes.apply("#{block_prefix}#{prefix}#{value}#{suffix}#{block_suffix}")
        end

        def apply_block_layout(value)
          lines = value.to_s.lines(chomp: true)
          lines = [""] if lines.empty?

          if indent&.positive?
            indentation = (indent_token || " ") * indent
            lines = lines.map { |line| "#{indentation}#{line}" }
          end

          rendered = lines.join("\n")
          return rendered unless margin.to_i.positive?

          blank = Array.new(margin.to_i, "").join("\n")
          "#{blank}\n#{rendered}\n#{blank}"
        end

        private

        def ansi_codes
          UI::ANSICodes.new(
            attributes: ATTRIBUTES.select { |attribute| public_send(attribute) },
            foreground: color,
            background: background_color
          )
        end

        def self.symbolize_keys(value)
          value.to_h.each_with_object({}) { |(key, item), result| result[key.to_sym] = item }
        end

        def self.normalize_color(value)
          return if value.nil?
          return value if value.is_a?(Integer)
          return value.to_i if value.to_s.match?(/\A\d+\z/)

          value
        end
      end

      def self.builtin(name)
        key = name.to_s.tr("-", "_").to_sym
        raise ArgumentError, "unknown markdown style: #{name.inspect}" unless BUILT_INS.key?(key)

        from_hash(BUILT_INS.fetch(key))
      end

      def self.from(value)
        return value if value.is_a?(self)
        return builtin(value) if value.is_a?(String) || value.is_a?(Symbol)

        from_hash(value || BUILT_INS.fetch(:dark))
      end

      def self.from_hash(value)
        new(value.to_h)
      end

      def initialize(styles = {})
        styles = styles.transform_keys(&:to_sym)
        @styles = ELEMENTS.each_with_object({}) do |element, result|
          result[element] = Style.from(styles[element] || {})
        end.freeze
      end

      def [](name)
        @styles.fetch(name.to_sym) { Style.from({}) }
      end

      def heading(level)
        self[:heading].inherit_visual(self[:"h#{level}"])
      end
    end
  end
end
