# frozen_string_literal: true

require 'devise/api'
require 'pry'
require 'awesome_print'

# Requre all services for testing
Dir[File.join(File.dirname(__FILE__), '../app/services/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
