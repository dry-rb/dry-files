# frozen_string_literal: true

module Dry
  class Files
    # Cross Operating System path
    #
    # It's used by the memory adapter to ensure that hardcoded string paths
    # are transformed into portable paths that respect the Operating System
    # directory separator.
    module Path
      class << self
        # Transform the given path into a path that respect the Operating System
        # directory separator.
        #
        # @param path [String,Pathname,Array<String,Pathname>] the path to transform
        #
        # @return [String] the resulting path
        #
        # @since 0.1.0
        # @api private
        #
        # @example Portable path
        #   require "dry/files/path"
        #
        #   path = "path/to/file"
        #
        #   Dry::Files::Path.call(path)
        #     # => "path/to/file" on UNIX based Operating System
        #
        #   Dry::Files::Path.call(path)
        #     # => "path\to\file" on Windows Operating System
        #
        # @example Join nested tokens
        #   require "dry/files/path"
        #
        #   path = ["path", ["to", ["nested", "file"]]]
        #
        #   Dry::Files::Path.call(path)
        #     # => "path/to/nested/file" on UNIX based Operating System
        #
        #   Dry::Files::Path.call(path)
        #     # => "path\to\nested\file" on Windows Operating System
        def call(*path)
          path = Array(path).flatten
          tokens = path.map do |token|
            split(token)
          end

          tokens
            .flatten
            .join(::File::SEPARATOR)
        end
        alias_method :[], :call
      end

      # Split path according to the current Operating System directory separator
      #
      # @param path [String,Pathname] the path to split
      #
      # @return [Array<String>] the split path
      #
      # @since 0.1.0
      # @api private
      def self.split(path)
        path.to_s.split(%r{\\|/})
      end
    end
  end
end
