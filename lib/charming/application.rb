# frozen_string_literal: true

module Charming
  class Application
    class << self
      def routes(&block)
        @routes ||= Router.new(namespace: namespace)
        @routes.draw(&block) if block
        @routes
      end

      def namespace
        name&.split("::")&.then { |parts| parts[0...-1].join("::") }
      end
    end

    attr_accessor :task_executor
    attr_reader :session

    def initialize
      @session = {}
    end

    def routes
      self.class.routes
    end
  end
end
