# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :standard do
  sh "bin/lint"
end

task default: %i[spec standard]
