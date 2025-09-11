# frozen_string_literal: true

require_relative "support/coverage"

$LOAD_PATH.unshift "lib"
require "dry/files"
require "pathname"
require_relative "./support/rspec"

%w[support].each do |dir|
  Dir[File.join(Dir.pwd, "spec", dir, "**", "*.rb")].each do |file|
    unless file["support/warnings.rb"]
      require_relative file
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed
end
