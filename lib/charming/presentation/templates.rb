# frozen_string_literal: true

module Charming
  module Presentation
    # Templates resolves and renders view templates by name. Template handlers are registered
    # for file extensions (e.g., `.tui.erb`) and the resolver searches `app/views/<name><ext>`
    # under the application root, falling back through registered extensions when the first
    # match is not found.
    module Templates
      # A resolved template: an on-disk *path* paired with the *handler* responsible for rendering it.
      ResolvedTemplate = Data.define(:path, :handler) do
        # Renders the template against *view* by delegating to the registered handler.
        def render(view)
          handler.render(path, view)
        end
      end

      # Raised when no template file matches the given name under the application root.
      MissingTemplateError = Class.new(Error)

      class << self
        # Registers a template *handler* for a file *extension* (e.g., ".tui.erb" => ErbHandler).
        # The handler responds to `.render(path, view)`.
        def register(extension, handler)
          handlers[extension] = handler
        end

        # Resolves a template by *name* under `app/views` of *root* (defaults to the current
        # working directory). Raises MissingTemplateError when no matching file exists.
        def resolve(name, root: nil)
          views_root = File.join(root || Dir.pwd, "app", "views")
          searched_paths = candidate_paths(views_root, name.to_s)

          searched_paths.each do |path|
            next unless File.file?(path)

            return ResolvedTemplate.new(path: path, handler: handler_for(path))
          end

          raise MissingTemplateError, "Missing template #{name.inspect}. Searched: #{searched_paths.join(", ")}"
        end

        # Hash of registered handlers keyed by extension. Populated by `register`.
        def handlers
          @handlers ||= {}
        end

        private

        # Returns candidate paths under *views_root* for *name*. When the bare path has a known
        # extension, returns it directly; otherwise returns the path with each registered extension
        # appended (in registration order).
        def candidate_paths(views_root, name)
          path = File.expand_path(name, views_root)
          return [path] if handler_for(path)

          handlers.keys.map { |extension| "#{path}#{extension}" }
        end

        # Looks up the handler whose registered extension matches the end of *path*. Returns nil
        # when no handler matches.
        def handler_for(path)
          handlers.find { |extension, _handler| path.end_with?(extension) }&.last
        end
      end
    end
  end
end
