# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

$LOAD_PATH.unshift File.dirname(__FILE__)

# SimpleCov must start before the gem and the dummy app are required so their files are tracked
require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
  add_filter %r{^/spec/}
  add_filter 'lib/devise/api/version.rb' # loaded by the gemspec before SimpleCov starts
  track_files '{app,lib}/**/*.rb'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Lib', 'lib'
  minimum_coverage line: 95 if ENV['CI'] || ENV['ENFORCE_COVERAGE']
end

require 'devise/api'
require 'dummy/config/environment'
require 'pry'
require 'awesome_print'
require 'database_cleaner'
require 'rspec/rails'

Dir["#{File.dirname(__FILE__)}/supports/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RSpec::Rails::RequestExampleGroup, type: :request

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
end

# For generators
require 'rails/generators/test_case'
require 'devise/api/generators/install_generator'
