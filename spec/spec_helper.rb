# frozen_string_literal: true

require 'bundler/setup'
require 'request_store'
require 'trailer'
require 'trailer/storage/null'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |cnf|
    cnf.syntax = :expect
  end

  config.before do
    Trailer.configure do |cnf|
      cnf.enabled = true
      cnf.storage = Trailer::Storage::Null
    end
    RequestStore.store[:trailer] = nil
  end
end
