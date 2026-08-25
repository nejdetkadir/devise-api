# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec)

# Full-suite runs enforce the SimpleCov minimum; single-file `rspec` runs do not.
task :enforce_coverage do
  ENV['ENFORCE_COVERAGE'] = '1'
end
task rspec: :enforce_coverage

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[rspec rubocop]
