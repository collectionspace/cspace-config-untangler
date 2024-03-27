require "bundler/setup"
require "rspec/custom/matchers/match_csv"

require "cspace_config_untangler"
require_relative "helpers"
require "dry/configurable/test_interface"

module CspaceConfigUntangler
  enable_test_interface
end

RSpec.configure do |config|
  config.include Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.after(:each) { CCU.reset_config }
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
