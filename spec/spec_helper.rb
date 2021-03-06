# frozen_string_literal: true

require 'simplecov'
require 'fakeredis'

RSpec.configure do |config|
  config.before(:example) { Redis::Connection::Memory.reset_all_databases }

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  RSpec::Matchers.define_negated_matcher :not_change, :change
end
