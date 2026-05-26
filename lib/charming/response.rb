# frozen_string_literal: true

module Charming
  Response = Data.define(:kind, :body, :path) do
    def self.render(body)
      new(kind: :render, body: body, path: nil)
    end

    def self.navigate(path)
      new(kind: :navigate, body: "", path: path)
    end

    def self.quit
      new(kind: :quit, body: "", path: nil)
    end

    def navigate?
      kind == :navigate
    end

    def quit?
      kind == :quit
    end
  end
end
