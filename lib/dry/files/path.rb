# frozen_string_literal: true

module Dry
  class Files
    module Path
      class << self
        def call(*path)
          path = Array(path).flatten
          tokens = path.map do |token|
            token.to_s.split(%r{\\|/})
          end

          tokens
            .flatten
            .join(::File::SEPARATOR)
        end
        alias_method :[], :call
      end
    end
  end
end
