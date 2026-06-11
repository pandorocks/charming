# frozen_string_literal: true

require "erb"

module Charming
  module Templates
    # ErbHandler renders `.tui.erb` / `.txt.erb` templates. Compiled ERB objects are
    # cached per path: in development the cache is invalidated by file mtime so edits
    # show up live; in other environments templates are compiled once.
    class ErbHandler
      @cache = {}
      @mutex = Mutex.new

      class << self
        def render(path, view)
          erb(path).result(view.template_binding)
        end

        # Clears the compiled-template cache (used by tests).
        def reset_cache
          @mutex.synchronize { @cache.clear }
        end

        private

        # Returns the compiled ERB for *path*, recompiling in development when the
        # file's mtime changes.
        def erb(path)
          @mutex.synchronize do
            entry = @cache[path]
            mtime = Charming.env.development? ? File.mtime(path) : nil
            if entry.nil? || (mtime && entry[:mtime] != mtime)
              entry = {erb: compile(path), mtime: mtime}
              @cache[path] = entry
            end
            entry[:erb]
          end
        end

        def compile(path)
          ERB.new(File.read(path), trim_mode: "-")
        end
      end
    end
  end
end
