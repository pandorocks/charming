# frozen_string_literal: true

module Charming
  module Generators
    class ModelGenerator < AppFileGenerator
      Field = Data.define(:name, :type)
      VALID_TYPES = %w[string text integer float decimal boolean date datetime time].freeze

      def initialize(name, args, out:, destination:, force: false)
        super
        @fields = args.map { |arg| parse_field(arg) }
      end

      def generate
        raise Error, "Database support is not configured. Generate the app with --database sqlite3 first." unless database_configured?

        create_file(model_path, model)
        create_file(migration_path, migration)
        create_file(spec_path, spec)
      end

      private

      attr_reader :fields

      def suffix
        nil
      end

      def model_path
        File.join("app", "models", "#{name.snake_name}.rb")
      end

      def migration_path
        File.join("db", "migrate", "#{timestamp}_create_#{table_name}.rb")
      end

      def spec_path
        File.join("spec", "models", "#{name.snake_name}_spec.rb")
      end

      def model
        %(# frozen_string_literal: true

module #{app_name.class_name}
  class #{name.class_name} < ApplicationRecord
  end
end
)
      end

      def migration
        %(# frozen_string_literal: true

class Create#{table_class_name} < ActiveRecord::Migration[8.1]
  def change
    create_table :#{table_name} do |t|
#{field_lines}      t.timestamps
    end
  end
end
)
      end

      def spec
        %(# frozen_string_literal: true

require "#{app_name.snake_name}"

RSpec.describe #{app_name.class_name}::#{name.class_name} do
  it "inherits from ApplicationRecord" do
    expect(described_class.superclass).to eq(#{app_name.class_name}::ApplicationRecord)
  end
end
)
      end

      def field_lines
        fields.map { |field|
          %(      t.#{field.type} :#{field.name}
)
        }.join
      end

      def parse_field(value)
        field_name, type = value.split(":", 2)
        raise Error, "Invalid field: #{value.inspect}" unless field_name && type
        raise Error, "Invalid field name: #{field_name.inspect}" unless Name::VALID_NAME.match?(field_name)
        raise Error, "Unsupported field type: #{type.inspect}" unless VALID_TYPES.include?(type)

        Field.new(name: field_name, type: type)
      end

      def database_configured?
        File.exist?(File.join(destination, "config", "database.rb")) &&
          File.exist?(File.join(destination, "app", "models", "application_record.rb"))
      end

      def table_name
        pluralize(name.snake_name)
      end

      def table_class_name
        table_name.split("_").map(&:capitalize).join
      end

      def pluralize(value)
        return value.sub(/y\z/, "ies") if value.end_with?("y")
        return "#{value}es" if value.match?(/(?:s|x|z|ch|sh)\z/)

        "#{value}s"
      end

      def timestamp
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
