# frozen_string_literal: true

require "rspec/expectations"

RSpec::Matchers.define :have_content do |expected|
  match do |actual|
    File.read(actual) == expected
  end

  failure_message do |actual|
    "expected that `#{actual}' would have content '#{expected}', but it has '#{File.read(actual)}'"
  end
end

RSpec::Matchers.define :be_found do
  match do |actual|
    subject.exist?(actual)
  end

  failure_message do |actual|
    "expected `#{actual}' to exist"
  end
end

RSpec::Matchers.define :have_file_contents do |expected|
  match do |actual|
    subject.read(actual) == expected
  end

  failure_message do |actual|
    "expected that `#{actual}' would have content '#{expected}', but it has '#{subject.read(actual)}'"
  end
end
