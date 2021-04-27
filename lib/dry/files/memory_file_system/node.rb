# frozen_string_literal: true

require "English"
require "stringio"

module Dry
  class Files
    class MemoryFileSystem
      class Node
        # File mode inspired by https://www.calleluks.com/flags-bitmasks-and-unix-file-system-permissions-in-ruby/
        MODE_USER_READ      = 0b100000000
        MODE_USER_WRITE     = 0b010000000
        MODE_USER_EXECUTE   = 0b001000000
        MODE_GROUP_READ     = 0b000100000
        MODE_GROUP_WRITE    = 0b000010000
        MODE_GROUP_EXECUTE  = 0b000001000
        MODE_OTHERS_READ    = 0b000000100
        MODE_OTHERS_WRITE   = 0b000000010
        MODE_OTHERS_EXECUTE = 0b000000001

        private_constant :MODE_USER_READ
        private_constant :MODE_USER_WRITE
        private_constant :MODE_USER_EXECUTE
        private_constant :MODE_GROUP_READ
        private_constant :MODE_GROUP_WRITE
        private_constant :MODE_GROUP_EXECUTE
        private_constant :MODE_OTHERS_READ
        private_constant :MODE_OTHERS_WRITE
        private_constant :MODE_OTHERS_EXECUTE

        DEFAULT_DIRECTORY_MODE = MODE_USER_READ | MODE_USER_WRITE |
                                 MODE_USER_EXECUTE | MODE_GROUP_READ | MODE_GROUP_EXECUTE |
                                 MODE_OTHERS_READ | MODE_GROUP_EXECUTE
        private_constant :DEFAULT_DIRECTORY_MODE

        DEFAULT_FILE_MODE = MODE_USER_READ | MODE_USER_WRITE | MODE_GROUP_READ | MODE_OTHERS_READ
        private_constant :DEFAULT_FILE_MODE

        MODE_BASE = 16
        private_constant :MODE_BASE

        ROOT_PATH = "/"
        private_constant :ROOT_PATH

        def self.root
          new(ROOT_PATH)
        end

        attr_reader :path, :mode

        def initialize(path, mode = DEFAULT_DIRECTORY_MODE)
          @path = path
          @children = nil
          @content = nil
          @mode = mode
        end

        def get(segment)
          @children&.fetch(segment, nil)
        end

        def set(segment)
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
          @mode = DEFAULT_FILE_MODE
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

        def chmod!(mode)
          @mode = mode.to_s(MODE_BASE).hex
        end

        def executable?
          (mode & MODE_USER_EXECUTE).positive?
        end
      end
    end
  end
end
