# frozen_string_literal: true

require "uri"

module Charming
  module Markdown
    # URLResolver resolves Markdown link destinations against an optional base URL.
    class URLResolver
      def initialize(base_url: nil)
        @base_url = base_url
      end

      def resolve(value)
        return value if base_url.to_s.empty? || value.empty?
        return value if URI.parse(value).absolute?

        URI.join(base_url, value).to_s
      rescue URI::InvalidURIError
        value
      end

      private

      attr_reader :base_url
    end
  end
end
