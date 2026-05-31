# frozen_string_literal: true

require "erb"

module Charming
  module Presentation
    module Templates
      class ErbHandler
        def self.render(path, view)
          ERB.new(File.read(path), trim_mode: "-").result(view.template_binding)
        end
      end
    end
  end
end
