# frozen_string_literal: true

module Charming
  Response = Data.define(:kind, :body) do
    def self.render(body)
      new(kind: :render, body: body)
    end

    def self.quit
      new(kind: :quit, body: "")
    end

    def quit?
      kind == :quit
    end
  end
end
