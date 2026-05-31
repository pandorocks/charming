# frozen_string_literal: true

module Charming
  module Presentation
    module Templates
      ResolvedTemplate = Data.define(:path, :handler) do
        def render(view)
          handler.render(path, view)
        end
      end

      MissingTemplateError = Class.new(Error)

      class << self
        def register(extension, handler)
          handlers[extension] = handler
        end

        def resolve(name, root: nil)
          views_root = File.join(root || Dir.pwd, "app", "views")
          searched_paths = candidate_paths(views_root, name.to_s)

          searched_paths.each do |path|
            next unless File.file?(path)

            return ResolvedTemplate.new(path: path, handler: handler_for(path))
          end

          raise MissingTemplateError, "Missing template #{name.inspect}. Searched: #{searched_paths.join(", ")}"
        end

        def handlers
          @handlers ||= {}
        end

        private

        def candidate_paths(views_root, name)
          path = File.expand_path(name, views_root)
          return [path] if handler_for(path)

          handlers.keys.map { |extension| "#{path}#{extension}" }
        end

        def handler_for(path)
          handlers.find { |extension, _handler| path.end_with?(extension) }&.last
        end
      end
    end
  end
end
