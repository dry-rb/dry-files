# frozen_string_literal: true

module RSpec
  module Helpers
    module RubyEngine
      private

      def with_ruby_engine(engine, &blk)
        result = if RUBY_ENGINE == "ruby"
                   :mri
                 elsif RUBY_PLATFORM == "java"
                   :jruby
                 else
                   raise "unkwnown Ruby engine: `#{result}'"
                 end

        blk.call if result == engine
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Helpers::RubyEngine)
end
