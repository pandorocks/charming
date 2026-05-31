# frozen_string_literal: true

module Charming
  module Generators
    class Name
      VALID_NAME = /\A[a-z][a-z0-9_]*\z/

      attr_reader :snake_name

      def initialize(value)
        @snake_name = value.to_s
        raise Error, "Invalid name: #{value}" unless VALID_NAME.match?(@snake_name)
      end

      def class_name
        snake_name.split("_").map(&:capitalize).join
      end

      def controller_class_name
        "#{class_name}Controller"
      end

      def component_class_name
        "#{class_name}Component"
      end
    end
  end
end
