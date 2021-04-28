# frozen_string_literal: true

require "dry/files/path"

module Dry
  class Files
    # Memory File System abstraction to support `Dry::Files`
    #
    # @since x.x.x
    # @api private
    class MemoryFileSystem
      require_relative "./memory_file_system/node"

      def initialize(root: Node.root)
        @root = root
      end

      def touch(path)
        path = Path[path]
        raise IOError, Errno::EISDIR.new(path.to_s) if directory?(path)

        content = read(path) if exist?(path)
        write(path, content || EMPTY_CONTENT)
      end

      def join(*path)
        Path[path]
      end

      def pwd
        @root.segment
      end

      def cp(source, destination)
        content = read(source)
        write(destination, content)
      end

      def rm(path)
        path = Path[path]
        file = nil
        parent = @root
        node = @root

        for_each_segment(path) do |segment|
          break unless node

          file = segment
          parent = node
          node = node.get(segment)
        end

        raise IOError, Errno::ENOENT.new(path.to_s) if node.nil?
        raise IOError, Errno::EPERM.new(path.to_s) if node.directory?

        parent.unset(file)
      end

      def rm_rf(path)
        path = Path[path]
        file = nil
        parent = @root
        node = @root

        for_each_segment(path) do |segment|
          break unless node

          file = segment
          parent = node
          node = node.get(segment)
        end

        raise IOError, Errno::ENOENT.new(path.to_s) if node.nil?

        parent.unset(file)
      end

      def chdir(path)
        path = Path[path]
        directory = find(path)

        raise IOError, Errno::ENOENT.new(path.to_s) if directory.nil?
        raise IOError, Errno::ENOTDIR.new(path.to_s) unless directory.directory?

        current_root = @root
        @root = directory
        yield
      ensure
        @root = current_root
      end

      def mkdir(path)
        path = Path[path]
        node = @root

        for_each_segment(path) do |segment|
          node = node.set(segment)
        end
      end

      def mkdir_p(path)
        path = Path[path]

        mkdir(
          ::File.dirname(path)
        )
      end

      EMPTY_CONTENT = nil
      private_constant :EMPTY_CONTENT

      def open(path, *, &blk)
        file = write(path, EMPTY_CONTENT)
        blk.call(file)
      end

      def read(path)
        path = Path[path]
        raise IOError, Errno::EISDIR.new(path.to_s) if directory?(path)

        file = find_file(path)
        raise IOError, Errno::ENOENT.new(path.to_s) if file.nil?

        file.read
      end

      def write(path, *content)
        path = Path[path]
        node = @root

        for_each_segment(path) do |segment|
          node = node.set(segment)
        end

        node.write(*content)
        node
      end

      def chmod(path, mode)
        path = Path[path]
        node = find(path)

        raise IOError, Errno::ENOENT.new(path.to_s) if node.nil?

        node.chmod = mode
      end

      def readlines(path)
        path = Path[path]
        node = find(path)

        raise IOError, Errno::ENOENT.new(path.to_s) if node.nil?
        raise IOError, Errno::EISDIR.new(path.to_s) if node.directory?

        node.readlines
      end

      def exist?(path)
        path = Path[path]

        !find(path).nil?
      end

      def directory?(path)
        path = Path[path]
        !find_directory(path).nil?
      end

      def executable?(path)
        path = Path[path]

        node = find(path)
        return false if node.nil?

        node.executable?
      end

      private

      def for_each_segment(path, &blk)
        segments = Path.split(path)
        segments.each(&blk)
      end

      def find_directory(path)
        node = find(path)

        return if node.nil?
        return unless node.directory?

        node
      end

      def find_file(path)
        node = find(path)

        return if node.nil?
        return unless node.file?

        node
      end

      def find(path)
        node = @root

        for_each_segment(path) do |segment|
          break unless node

          node = node.get(segment)
        end

        node
      end
    end
  end
end
