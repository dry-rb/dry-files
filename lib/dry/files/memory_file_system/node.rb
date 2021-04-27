# frozen_string_literal: true

require "English"
require "stringio"

module Dry
  class Files
    class MemoryFileSystem
      class Node
        ROOT_PATH = "/"
        private_constant :ROOT_PATH

        def self.root
          new(ROOT_PATH)
        end

        attr_reader :path

        def initialize(path)
          @path = path
          @children = nil
          @content = nil
        end

        def get(segment)
          @children&.fetch(segment, nil)
        end

        def put(segment)
          @children ||= {}
          @children[segment] ||= self.class.new(segment)
        end

        def unset(segment)
          @children ||= {}
          @children.delete(segment)
        end

        def directory?
          !file?
        end

        def file?
          !@content.nil?
        end

        def file!(*content)
          @content = StringIO.new(content.join($RS))
        end

        alias_method :write, :file!

        def read
          @content.rewind
          @content.read
        end

        def readlines
          @content.rewind
          @content.readlines
        end
      end
    end
  end
end
