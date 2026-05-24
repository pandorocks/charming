# frozen_string_literal: true

module Charming
  class Application
    class << self
      def routes(&block)
        @routes ||= Router.new
        @routes.draw(&block) if block
        @routes
      end
    end

    attr_reader :session

    def initialize
      @session = {}
    end

    def routes
      self.class.routes
    end
  end
end
